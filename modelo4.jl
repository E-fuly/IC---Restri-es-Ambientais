#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 4                   #
# Modelagem: Esther Fuly da Costa   #                           
#####################################
using CSV
using Gurobi
using DataFrames
using JuMP
using LinearAlgebra

# ---------------------------- LEITURA ----------------------------- #
df_chuva = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados criados/Chuva_mês - Página1.csv",DataFrame)

# ----------------------------- DADOS ------------------------------ #

vol_inicial = [0,1500]
NH = 1
cm_termo = 10000
cm_hidro = [1001,1002]
vol_max = [1500,1700]
meses = 1
demanda = [1900, 1901, 1902, 1900, 1900]
chuva = Matrix(df_chuva[:,2:3])

###------------------------ # MODELO # ----------------------------------###

modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #
@variable(modelo, 0 <= termo[1:meses]<= cm_termo)
@variable(modelo, 0 <= q_hidro[1:meses,i = 1:NH] <= cm_hidro[i]) 
#@variable(modelo, 0 <= p_hidro[1:meses, i = 1:NH] <= cm_hidro[i]) 
@variable(modelo, 0 <= vol[1:meses,i = 1:NH] <= vol_max[i]) 
@variable(modelo, 0 <= s[1:meses, i = 1:NH])

# ---------------------- RESTRIÇÕES -------------------------------------- #
 for j in 1:meses
    @constraint(modelo, termo[j] + sum(q_hidro[j,:]) == demanda[j])
 end
 @constraint(modelo, vol[1,1:NH] .== vol_inicial[1:NH] .- q_hidro[1,1:NH] .+ chuva[1,1:NH] .-s[1,1:NH])
 #mes_anterior = 1
 for j in 2:meses
    @constraint(modelo, vol[j,1:NH] .== vol[j-1,1:NH] .- q_hidro[j,1:NH] .+chuva[j,1:NH] .-s[j,1:NH])
    #@constraint(modelo, vol[j,:] .== vol[mes_anterior,:] .- q_hidro[j,:] .+chuva[j,:] .-s[j,:])
    #mes_anterior = j
end
# -------------------- FUNÇÃO OBJETIVO ----------------------------------- #
@objective(modelo, Min, sum(termo[1:meses]))
optimize!(modelo)
print(modelo)
if termination_status(modelo) == MOI.OPTIMAL
 for j in 1:meses
    println(" Uso da termoelétrica no mês $j: ", value(termo[j]))
 for i in 1:NH
    println(" Uso da hidroelétrica $i no mês $j:  ", value(q_hidro[j,i]))
    println(" Volume da hidroelétrica $i no mês $j:  ", value(vol[j,i]))
    println("Vertimento da hidroelétrica $i no mês $j: ", value(s[j,i]))
 end
 end
 println("Valor ótimo da função objetivo: ", objective_value(modelo))
else
    println("O modelo não encontrou uma solução ótima.")
end
