# File:imputeMissingVar.R

# R code for imputting missing variables, such as: height and volume
# Ult. modificacion Jun 15, 2020
library(biometria)
library(lattice)
# carga lista de modelos
source("creaListaModelos.R")


dbase <- read.csv(file = "4biomass.csv", stringsAsFactors = F)
# table(dbase$predio)


# carga modelosParaIMV.csv
base.modelos <- read.csv("modelosParaIMV.csv", stringsAsFactors = F)
# seleccionar solo los modelos que se utilizaran
base.modelos <- subset(base.modelos, impute==1)

# rangos de variables respuesta
# rango.var.y <- read.csv("../data/rangoVarIndxSpp.csv", stringsAsFactors = F)

# data de entrada debe tener: esp, predio, anho.med
# base.modelos debe tener: esp, predio. anho, var.y, 

# imputacion de htot

IMV <- function(data = db.imp, data.modelos = base.modelos, var.y.imp="htot",intercept.y=NA){
base.modelos <- data.modelos

# subset de la variable y 
base.mod.var.y <- subset(base.modelos, var.y==var.y.imp)

# data de rangos por especie para la variable y
#rango.var.y <- subset(data.rangos, var.y == var.y.imp)

# genera otra columna de especie para hacer merge y corregir algunos datos
db.imp <- data
db.imp$esp2 <- db.imp$esp
db.imp$esp2[is.element(db.imp$esp, setdiff(unique(db.imp$esp), unique(base.mod.var.y$esp)))] <- 'ot'

# genera otra columna de predio para hacer merge y corregir algunos datos
db.imp$predio2 <- db.imp$predio
db.imp$predio2[is.element(db.imp$predio, setdiff(unique(db.imp$predio), unique(base.mod.var.y$predio)))] <- 'global'
# table(db.imp$predio2)

# que pasa si una especie no esta en un predio especifico  ---> se asigna el modelo global para la especie
for(i in unique(db.imp$esp2)){
  predios.i <- unique(base.mod.var.y$predio[base.mod.var.y$esp ==i])
  db.imp$predio2[db.imp$esp2 ==i & is.element(db.imp$predio, setdiff(unique(db.imp$predio2), predios.i))] <- "global"
}
# table(db.imp$predio2, db.imp$esp2)

# genera una columna esp2_predio2
db.imp$esp_predio <- paste(db.imp$esp2, db.imp$predio2, sep = '_')

base.mod.var.y$esp_predio <- paste(base.mod.var.y$esp, base.mod.var.y$predio, sep = '_')
unique(base.mod.var.y$esp_predio)

db.imp$anho.med2 <- db.imp$anho.med

# que pasa si una especie_predio_anho no esta en la tabla de modelos  ---> se asigna el modelo global para la especie_predio
for(i in unique(db.imp$esp_predio)){
  anho.i <- unique(base.mod.var.y$anho[base.mod.var.y$esp_predio ==i])
  db.imp$anho.med2[db.imp$esp_predio ==i & is.element(db.imp$anho.med, setdiff(unique(db.imp$anho.med2), anho.i))] <- 0
    }

table(db.imp$anho.med2, db.imp$predio2, db.imp$esp2)

# merge dbase con modelos a utilizar
db.imp.var.y <- unique(merge(db.imp, 
                     base.mod.var.y, 
                     by.x = c("esp2", "predio2", "anho.med2"),
                     by.y = c("esp", "predio", "anho")))
head(db.imp.var.y)


# primero crear las columnas x.1, x.2, ..., a partir de la informacion de la tabla baseModelos
db.imp.var.y$x.num.1 <- as.numeric(apply(db.imp.var.y, MARGIN = 1, function(fila){
  fila[fila["var.x.1"]]
}))
db.imp.var.y$x.num.2 <- apply(db.imp.var.y, MARGIN = 1, function(fila){
  fila[fila["var.x.2"]]
})
db.imp.var.y$x.num.3 <- apply(db.imp.var.y, MARGIN = 1, function(fila){
  fila[fila["var.x.3"]]
})
db.imp.var.y$x.num.4 <- apply(db.imp.var.y, MARGIN = 1, function(fila){
  fila[fila["var.x.4"]]
})

head(db.imp.var.y)

# imputacion de la variable y
db.imp.var.y$var.y.imp <- apply(X = db.imp.var.y, MARGIN = 1, function(fila){
  lista.modelos[[fila["modelo"]]](params = as.numeric(fila[grep(pattern = "b.hat.",
                                                               x = names(fila))]),
                                  X = as.numeric(fila[grep(pattern = "x.num.",
                                                           x = names(fila))])
                                   , intercept=intercept.y
                                  )})


# if(!is.na(rango.var.y)){
#   db.imp.var.y <- merge(db.imp.var.y, rango.var.y[,c("esp", "min.y", "max.y")],
#                         by.x="esp2", by.y="esp", all.x = T)
# 
#   db.imp.var.y$var.y.imp[db.imp.var.y$var.y.imp < db.imp.var.y$min.y] <- db.imp.var.y$min.y[db.imp.var.y$var.y.imp < db.imp.var.y$min.y]
#   db.imp.var.y$var.y.imp[db.imp.var.y$var.y.imp > db.imp.var.y$max.y] <- db.imp.var.y$max.y[db.imp.var.y$var.y.imp > db.imp.var.y$max.y]
# }


print(xyplot(var.y.imp~x.num.1|esp_predio.x+factor(anho.med2), data=db.imp.var.y,
             xlim=c(0,max(db.imp.var.y$x.num.1)*1.1),
             ylim=c(0,max(db.imp.var.y$var.y.imp)*1.1),
             las=1, type="p",
             as.table=T,
             auto.key = T))



# pega htot a dbase
out <- db.imp.var.y 
}

# Imputacion de variables 
dbase <- subset(dbase, esp=="nd" |  esp=="nal" | esp=="nob")
# unique(dbase$proy.id)
table(dbase$esp)

histogram(~dap|esp, data = dbase,
          xlab = "Diametro a la altura del pecho (d)",
          ylab = "Porcentaje del total",
          main = "Distribucion del dap por especie")

histogram(~dap|predio+esp, data = dbase)



histogram(~htot|esp, data = dbase,
          xlab = "Altura total (m)",
          ylab = "Porcentaje del total",
          main = "Distribucion de la altura total por especie")

histogram(~htot|predio+esp, data = dbase)


histogram(~dw.total|esp, data = dbase,
          xlab = "Biomasa total (Kg)",
          ylab = "Porcentaje del total",
          main = "Distribucion de la biomasa total por especie")
histogram(~dw.total|predio+esp, data = dbase)

boxplot(dbase$dap~dbase$esp, ylab="dap (cm)", 
        main = "Distribucion del dap por especie")

boxplot(dbase$htot~dbase$esp, ylab="Altura total (m)",
        main = "Distribucion de la altura por especie")

boxplot(dbase$dw.total~dbase$esp,ylab="Biomasa total (Kg)",                                 
        main = "Distribucion de la Biomasa total por especie")


summary(dbase$dap)
summary(dbase$htot)
summary(dbase$dw.total)


pairs(dbase[,c("dw.total","dap","htot")])

xyplot(dw.total~dap|esp, data = dbase)
xyplot(dw.total~htot|esp, data = dbase)
xyplot(htot~dap|esp, data = dbase)


dbase$anho.med <- 2020
db.imp <- dbase
db.imp$h.ori <- db.imp$htot
db.imp$dbh <- db.imp$dap
db.imp$htot <- NULL
db.imp$vtot <- NULL
db.imp$wtot <- NULL


# Altura total
message("Comienzo de imputacion de variable htot")
names(db.imp)
db.htot <- IMV(data = db.imp, data.modelos = base.modelos, var.y.imp="htot", intercept.y = 1.3)


db.htot$htot <- db.htot$var.y.imp

xyplot(htot+h.ori~dbh|esp, data = db.htot)
xyplot(htot+h.ori~dbh|esp+predio2, data = db.htot)


db.htot <- plotIdGenerator(db.htot,plot.id.latex = F)
db.htot <- treeIdGenerator(db.htot,tree.id.anho = T)
db.imp <- plotIdGenerator(db.imp,plot.id.latex = F)
db.imp <- treeIdGenerator(db.imp,tree.id.anho = T)

db.imp <- merge(db.imp, db.htot[,c("tree.id.anho", "htot")], by="tree.id.anho")

names(db.htot)
names(db.imp)

head(db.imp)
message("Fin de imputacion de variable htot")


# Volumen total
message("Comienzo de imputacion de variable vtot")
db.vtot <- IMV(data = db.imp, data.modelos = base.modelos, var.y.imp="vtot",intercept.y = 1.3 )

head(db.vtot)
db.vtot$vtot <- db.vtot$var.y.imp

xyplot(vtot~dbh|esp, data = db.vtot)
xyplot(vtot~dbh|esp+predio2, data = db.vtot)


head(db.vtot$modelo)
db.vtot <- merge(db.imp, db.vtot[,c("tree.id.anho", "vtot")], by="tree.id.anho")
db.imp <- db.vtot
head(db.imp)
message("Fin de imputacion de variable vtot")


# Biomasa total
message("Comienzo de imputacion de variable wtot")
db.wtot <- IMV(data = db.imp, data.modelos = base.modelos, var.y.imp="wtot", intercept.y = 1.3)
db.wtot$wtot <- db.wtot$var.y.imp
xyplot(wtot+dw.total~dbh|esp+modelo, data = db.wtot)

db.wtot <- merge(db.imp, db.wtot[,c("tree.id.anho","wtot")], by="tree.id.anho")
db.imp <- db.wtot
message("Fin de imputacion de variable wtot")


# carbono
message("Comienzo de imputacion de variable carbono")
# momentaneamente se utilizara una tasa de carbono del 50 %
db.imp$carbono <- db.imp$wtot*0.5
message("Fin de imputacion de variable carbono")

head(db.imp)
table(unique(db.imp)[,"esp"])

summary(db.imp$wtot)

db.imp2 <- subset(db.imp, esp!="nd")
xyplot(wtot+dw.total~dbh|esp, data = db.imp2)

