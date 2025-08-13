#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 3                   #
#Modelagem por: Esther Fuly da Costa#                           
#####################################
using CSV
using Gurobi
using DataFrames
using JuMP
using LinearAlgebra

# ---------------------------- LEITURA ----------------------------- #
df_chuva = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados criados/Chuva_mês - Página1.csv",DataFrame)

# ----------------------------- DADOS ------------------------------ #

vol_inicial = 1300
cm_termo = 1000
cm_hidro = 1000
vol_max = 1500
meses = 5
demanda = [900, 900, 900, 900, 900]
chuva = Array(df_chuva[:,2])

###------------------------ # MODELO # ----------------------------------###

modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #
@variable(modelo, 0 <= termo[1:meses]<= cm_termo)
@variable(modelo, 0 <= hidro[1:meses]<=cm_hidro)
@variable(modelo, 0 <= vol[1:meses]<=vol_max)
@variable(modelo, 0 <= s[1:meses])

# ---------------------- RESTRIÇÕES -------------------------------------- #
 for j in 1:meses
    @constraint(modelo, termo[j] + hidro[j] == demanda[j])
 end
 @constraint(modelo, vol[1] == vol_inicial - hidro[1]+chuva[1]-s[1])
 #mes_anterior = 1
 for j in 2:meses
    @constraint(modelo, vol[j] == vol[j-1] - hidro[j]+chuva[j]-s[j])
    #@constraint(modelo, vol[j] == vol[mes_anterior] - hidro[j]+chuva[j]-s[j])
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
println("Vertimento no mês $j: ", value(s[j]))
 end
 println("Valor ótimo da função objetivo: ", objective_value(modelo))
else
    println("O modelo não encontrou uma solução ótima.")
end
