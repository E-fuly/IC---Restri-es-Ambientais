#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 2                   #
#Modelagem por: Esther Fuly da Costa#                           
#####################################
using CSV
using Gurobi
using DataFrames
using JuMP
using LinearAlgebra

# ----------------------------- DADOS ------------------------------ #

vol_inicial = 1300
meses = 3
demanda = [1000, 1000, 1000]

###------------------------ # MODELO # ----------------------------------###

modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #
@variable(modelo, 0 <= termo[1:meses])
@variable(modelo, 0 <= hidro[1:meses])
@variable(modelo, 0 <= vol[1:meses])

# ---------------------- RESTRIÇÕES -------------------------------------- #
 for j in 1:meses
    @constraint(modelo, termo[j] + hidro[j] == demanda[j])
 end
 @constraint(modelo, vol[1] == vol_inicial - hidro[1])
#mes_anterior = 1
 for j in 2:meses
    @constraint(modelo, vol[j] == vol[j-1] - hidro[j])
    #@constraint(modelo, vol[j] == vol[mes_anterior] - hidro[j])
#mes_anterior = j
end
# -------------------- FUNÇÃO OBJETIVO ----------------------------------- #
@objective(modelo, Min, sum(termo[1:meses]))

optimize!(modelo)
print(modelo)
if termination_status(modelo) == MOI.OPTIMAL
 for j in 1:meses
println(" Uso da termoelétrica no mês $j: ", value(termo[j]))
println(" Uso da hidroelétrica no mês $j:  ", value(hidro[j]))
println(" Volume no mês $j:  ", value(vol[j]))
 end
 println("Valor ótimo da função objetivo: ", objective_value(modelo))
else
    println("O modelo não encontrou uma solução ótima.")
end
