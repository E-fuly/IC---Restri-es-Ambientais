#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte 8                   #
#Modelagem por: Esther Fuly da Costa#                           
#####################################
using CSV
using Gurobi
using DataFrames
using JuMP
using LinearAlgebra

# ---------------- LEITURA --------------------- #
df_ch = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados Kenny/Afluências - CenariosAfluencias.csv",DataFrame)
df_termo = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados Kenny/Termicas - Termicas.csv.csv", DataFrame)
df_hidro = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados Kenny/Hidro - Hidro.csv.csv",DataFrame)
df_demanda = CSV.read("C:/Users/fulyl/Downloads/IC/Dados/Dados Kenny/Demanda - Demanda.csv",DataFrame)
# ---------------- DADOS --------------------- #
v₀ = Array(df_hidro[:,9])
#vmax = Array(df_hidro[:,6])
vmax = [10000, 11000, 12000, 13000, 14000, 15000, 18000]
ptMax = Array(df_termo[:,4])
phMax = Array(df_hidro[:,5])
qhMax =Array(df_hidro[:,8])
ρ = Array(df_hidro[:,7])
NH = 7
NG = 5
d = Array(df_demanda[:,2:13])
mes = 6
ch = Matrix(df_ch[:, 3:14])
CVU = Array(df_termo[:,5])
qt_mon = [0,1,2,0,1,1,1,0]
qs_mon = [0 0 0 0 0 0 0; 1 0 0 0 0 0 0; 2 4 0 0 0 0 0; 0 0 0 0 0 0 0; 3 0 0 0 0 0 0; 5 0 0 0 0 0 0; 6 0 0 0 0 0 0; 0 0 0 0 0 0 0]
# ---------------- # MODELO # --------------------- #
function roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU) 
end   
modelo = Model(Gurobi.Optimizer)
# ---------------- VARIÁVEIS DE ESTADO --------------------- #  
@variable(modelo, 0 <=v[1:mes, i= 1:NH] <= vmax[i] )
# ---------------- VARIÁVEIS --------------------- #  
@variable(modelo, 0 <= pt[1:mes, i= 1:NG]<= ptMax[i])
@variable(modelo, 0 <= ph[1:mes, i=1:NH]<= phMax[i])
@variable(modelo, 0 <= qh[1:mes, i=1:NH]<= qhMax[i])
@variable(modelo, 0 <= s[1:mes,1:NH])
# ---------------- RESTRIÇÕES --------------------- #  
for j in 1:mes
    @constraint(modelo, ph[j, 1:NH] .== qh[j, 1:NH] .* ρ[1:NH])
end

for i in 1:NH
    if qt_mon[i] == 0
          @constraint(modelo, v[1,i] .== v₀[i] .- qh[1,i]  .-s[1,i] .+ch[1,i])
       for j in 2:mes
          @constraint(modelo, v[j,i] .== v[j-1,i] .- qh[j,i] .+ch[j,i] .-s[j,i])
       end
    else
          @constraint(modelo, v[1,i] .== v₀[i] .- qh[1,i]  .-s[1,i] .+ch[1,i].+sum(qh[1,qs_mon[i,r]]+s[1,qs_mon[i,r]] for r in 1:qt_mon[i]))
       for j in 2:mes
          @constraint(modelo, v[j,i] .== v[j-1,i] .- qh[j,i] .+ch[j,i] .-s[j,i].+sum(qh[j,qs_mon[i,r]]+s[j,qs_mon[i,r]] for r in 1:qt_mon[i]))
       end 
    end
 end

for j in 1:mes
    @constraint(modelo, sum(pt[j, 1:NG]) + sum(ph[j, 1:NH]) == d[j])
 end
# ---------------- FUNÇÃO OBJETIVO --------------------- #  
@objective(modelo, Min, sum(sum(CVU[i]*pt[j,i] for i = 1:NG) for j = 1:mes))
optimize!(modelo)
print(modelo)

# ---------------- VERIFICAR A SOLUÇÃO ----------------- #

if termination_status(modelo) == MOI.OPTIMAL
    for j in 1:mes
        for i in 1:NG
            println("Uso da termoelétrica $i no mês $j: ", value(pt[j,i]))
        end
        for i in 1:NH
            println("Uso da hidroelétrica $i no mês $j: ", value(ph[j,i]))
            println("Volume da usina $i no mês $j: ", value(ph[j,i]))
        end
        println("Valor ótimo da função objetivo: ", objective_value(modelo))
    end
else
    println("O modelo não encontrou uma solução ótima.")
end
roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU)