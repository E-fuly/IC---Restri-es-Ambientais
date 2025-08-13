#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte meses_no_ano                  #
#Modelagem por: Esther Fuly da Costa#                           
#####################################

using CSV
using Gurobi
using DataFrames
using JuMP
using LinearAlgebra

# ---------------- LEITURA --------------------- #
df_ch = CSV.read("D:/IC/Dados/Dados Kenny/Afluências - CenariosAfluencias.csv", DataFrame)
df_termo = CSV.read("D:/IC/Dados/Dados Kenny/Termicas - Termicas.csv.csv", DataFrame)
df_hidro = CSV.read("D:/IC/Dados/Dados Kenny/Hidro - Hidro.csv.csv",DataFrame)
df_demanda = CSV.read("D:/IC/Dados/Dados Kenny/Demanda - Demanda.csv",DataFrame)

# ---------------- DADOs --------------------- #
v₀ = Array(df_hidro[:,9])
vmax = Array(df_hidro[:,6])
ptMax = Array(df_termo[:,4])
phMax = Array(df_hidro[:,5])
qhMax =Array(df_hidro[:,8])
ρ = Array(df_hidro[:,7])
NH = 7
# NH = 1
NG = 5
NAj = 2
d = Array(df_demanda[:,2:13])
anos = 1
meses_no_ano = 12
mes = meses_no_ano * anos
CVU = Array(df_termo[:,5])
def = 7643.82
qt_mon = [0,1,0,2,1,1,1]
qs_mon = [0 0 0 0 0 0 0; 1 0 0 0 0 0 0; 0 0 0 0 0 0 0; 2 4 0 0 0 0 0; 3 0 0 0 0 0 0; 5 0 0 0 0 0 0; 6 0 0 0 0 0 0]
ch = zeros(meses_no_ano, NH, NAj)
for r= 1:NAj #Numero de cenários
   for i = 1:NH, j =1:meses_no_ano # estamos pegando chuva por meses_no_ano meses pois é o que tem de dados, com mais anos, precisaremos repetir na coluna do lado
      ch[j,i,r] = df_ch[i+ (r-1)*7, j+2]
   end
end
# NCM = zeros(mes+1)
# NCM[1] = 0
# for g in 2:(mes+1)
#     NCM[g] = NAj^(g-2)
# end
# NCM = Int.(NCM)

NCM = zeros(Int,mes)
    for i = 1:mes
        NCM[i]= NAj^(i-1)
    end
NCM = Int.(NCM)
print("Vetor de Cenários: ",NCM)
# ---------------- # MODELO # --------------------- #
function roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU) 
end   
modelo = Model(Gurobi.Optimizer)
CH = zeros(mes,NH,NAj)
# for z in 0:anos-1
#    CH[z*meses_no_ano+1:(z+1)*meses_no_ano, :] = ch 
# end
for z in 0:anos-1
    CH[z*meses_no_ano+1:(z+1)*meses_no_ano, :, :] = ch
end
D = zeros(mes)
for z in 0:anos-1
    D[z*meses_no_ano+1:(z+1)*meses_no_ano] = d[1:meses_no_ano]
 end
# ---------------- vArIÁvEIs DE EsTADO --------------------- #  
@variable(modelo, 0 <=v[j=1:mes, i= 1:NH, a= 1:NCM[j+1]])
# ---------------- vArIÁvEIs --------------------- #  
@variable(modelo, 0 <= pt[j=1:mes, i= 1:NG, a=1:NAj]<= ptMax[i])
@variable(modelo, 0 <= ph[j=1:mes, i=1:NH,a= 1:NCM[j+1]]<= phMax[i])
@variable(modelo, 0 <= qh[j=1:mes, i=1:NH, a= 1:NCM[j+1]]<= qhMax[i])
@variable(modelo, 0 <= s[j=1:mes,1:NH,a= 1:NCM[j+1]])
@variable(modelo, 0 <= pd[j=1:mes])
# ---------------- rEsTrIÇÕEs --------------------- #  
# for j = 1:mes
#     for a = 1:NCM[j+1]
#     @constraint(modelo, ph[j, 1:NH, a] .== qh[j, 1:NH, a] .* ρ[1:NH])
#     end
# end

# Equilibrio Hidrico
for i = 1:NH
    global  k = 0
        k += 1 
        for r = 1:NAj
        if qt_mon[i] == 0
            @constraint(modelo, v[1,i,k] .== v₀[i] .- qh[1,i,k] .- s[1,i,k] .+ CH[1,i,1])
        else
            @constraint(modelo, v[1,i,k] .== v₀[i] .- qh[1,i,k]  .-s[1,i,k] .+ CH[1,i,1] .+sum(qh[1,qs_mon[i,l],k]+s[1,qs_mon[i,l],k] for l in 1:qt_mon[i]))
        end
    end  
end 
for i = 1:NH
    for j = 2:mes
    global  k = 0
        for a = 1:NCM[j-1]
            for r = 1:NAj
            k += 1 
                if qt_mon[i] == 0   
                @constraint(modelo, v[j,i,k] .== v[j-1, i, a] .- qh[j,i,k] .- s[j,i,k] .+ CH[j,i,r])
                else  
                @constraint(modelo, v[i,j,k] .== v[j-1,i, a] .- qh[j,i,k] .+ CH[j,i,r] .-s[j,i,k].+sum(qh[j,qs_mon[i,l],k]+s[j,qs_mon[i,l],k] for l in 1:qt_mon[i]))
                end
            end
        end
    end
end
# print("AQUI")
# sleep(10)

for j in 1:mes, c= 1:NAj
    @constraint(modelo, sum(pt[j, 1:NG,c ]) + sum(ph[j, 1:NH,c]) +pd[j] == D[j])
 end
# ---------------- FUNÇÃO OBJETIvO --------------------- #  
for c= 1:NAj
@objective(modelo, Min, NCM[c]*(sum(sum(CVU[i]*pt[j,i,c] for i = 1:NG) +def*pd[j] for j = 1:mes)))
end
optimize!(modelo)
roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU)