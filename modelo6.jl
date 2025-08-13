#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 6                   #
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

vol_inicial = [100,1100,1200,1300,1400]
NH = 5
NT = 3
cm_termo = [1000, 1001, 1002]
cm_hidro = [1001,1002,1003,1004,1005]
vol_max = [130,1400,1500,1600,1700]
meses = 2
demanda = [1900, 1901, 1902, 1900, 1900]
chuva = Matrix(df_chuva[:,2:6])
quant_mon = [0,1,2,0,1]
quais_mon = [0 0 0 0 0; 1 0 0 0 0; 2 4 0 0 0; 0 0 0 0 0; 3 0 0 0 0]

###------------------------ # MODELO # ----------------------------------###
#function roda_modelo_termo(vol_inicial, cm_termo, cm_hidro, vol_max, meses, demanda, chuva, quantidade_montante, quais_montante)
modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #
@variable(modelo, 0 <= termo[1:meses,i= 1:NT]<= cm_termo[i])
@variable(modelo, 0 <= q_hidro[1:meses,i = 1:NH] <= cm_hidro[i]) 
#@variable(modelo, 0 <= p_hidro[1:meses, i = 1:NH] <= cm_hidro[i]) 
@variable(modelo, 0 <= vol[1:meses,i = 1:NH] <= vol_max[i]) 
@variable(modelo, 0 <= s[1:meses, i = 1:NH])

# ---------------------- RESTRIÇÕES -------------------------------------- #
 for j in 1:meses
    @constraint(modelo, sum(termo[j,1:NT]) + sum(q_hidro[j,1:NH]) == demanda[j])
 end

for i in 1:NH
   if quant_mon[i] == 0
         @constraint(modelo, vol[1,i] .== vol_inicial[i] .- q_hidro[1,i]  .-s[1,i] .+chuva[1,i])
      for j in 2:meses
         @constraint(modelo, vol[j,i] .== vol[j-1,i] .- q_hidro[j,i] .+chuva[j,i] .-s[j,i])
      end
   else
         @constraint(modelo, vol[1,i] .== vol_inicial[i] .- q_hidro[1,i]  .-s[1,i] .+chuva[1,i].+sum(q_hidro[1,quais_mon[i,ind_mon]]+s[1,quais_mon[i,ind_mon]] for ind_mon in 1:quant_mon[i]))
      for j in 2:meses
         @constraint(modelo, vol[j,i] .== vol[j-1,i] .- q_hidro[j,i] .+chuva[j,i] .-s[j,i].+sum(q_hidro[j,quais_mon[i,ind_mon]]+s[j,quais_mon[i,ind_mon]] for ind_mon in 1:quant_mon[i]))
      end 
   end
end
# -------------------- FUNÇÃO OBJETIVO ----------------------------------- #
@objective(modelo, Min, sum(sum(termo[j,i] for i in 1:NT) for j in 1:meses))
optimize!(modelo)
print(modelo)
if termination_status(modelo) == MOI.OPTIMAL
 for j in 1:meses
    for i in 1:NT
    println(" Uso da termoelétrica $i no mês $j: ", value(termo[j,i]))
    end
 for i in 1:NH
    println(" Uso da hidroelétrica $i no mês $j:  ", value(q_hidro[j,i]))
    println(" Volume da hidroelétrica $i no mês $j:  ", value(vol[j,i]))
    println(" Vertimento da hidroelétrica $i no mês $j: ", value(s[j,i]))
 end
 end
 println("Valor ótimo da função objetivo: ", objective_value(modelo))
else
    println("O modelo não encontrou uma solução ótima.")
end
