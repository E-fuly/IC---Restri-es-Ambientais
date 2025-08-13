#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 1                   #
#Modelagem por: Esther Fuly da Costa#                           
#####################################
using CSV
using Gurobi
using DataFrames
using JuMP

# ----------------------------- DADOS ------------------------------ #

vol_inicial = 1300
demanda = 1000

###------------------------ # MODELO # ----------------------------------###

modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #
@variable(modelo, 0 <= termo)
@variable(modelo, 0 <= hidro)
@variable(modelo, 0 <= vol <= vol_inicial)

# ---------------------- RESTRIÇÕES -------------------------------------- #

@constraint(modelo, termo + hidro == demanda)

# -------------------- FUNÇÃO OBJETIVO ----------------------------------- #
@objective(modelo, Min, termo)

optimize!(modelo)
print(modelo)
termination_status(modelo) == MOI.OPTIMAL
println(" Uso da termoelétrica:", value(termo))
println(" Uso da hidroelétrica:", value(hidro))

