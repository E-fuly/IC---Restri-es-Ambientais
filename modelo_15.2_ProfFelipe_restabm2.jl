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
df_delfu_max = CSV.read("D:/IC/Dados/Dados Kenny/RestricoesSeguranca_defluencia_maxima.csv", DataFrame)
df_deflu_min = CSV.read("D:/IC/Dados/Dados Kenny/RestricoesSeguranca_defluencia_minima.csv",DataFrame)
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
N_f = 3 #Número de faixas - Isso deve estar zuado ou não usado porque tenho um número de faixas para cada usina
NAj = 1
d = Array(df_demanda[:,2:13])
anos = 1
meses_no_ano = 6
mes = meses_no_ano * anos

CVU = Array(df_termo[:,5])
def = 7643.82

qt_mon = [0,1,0,2,1,1,1]
qs_mon = [0 0 0 0 0 0 0; 1 0 0 0 0 0 0; 0 0 0 0 0 0 0; 2 3 0 0 0 0 0; 4 0 0 0 0 0 0; 5 0 0 0 0 0 0; 6 0 0 0 0 0 0]


ch = zeros(meses_no_ano, NH, NAj)
for r= 1:NAj #Numero de cenários
   for i = 1:NH, j =1:meses_no_ano # estamos pegando chuva por meses_no_ano meses pois é o que tem de dados, com mais anos, precisaremos repetir na coluna do lado
      ch[j,i,r] = df_ch[i+ (r-1)*7, j+2]
   end
end

NCM = zeros(Int,mes)
    for g = 1:mes
        NCM[g]= NAj^(g-1)
    end
NCM = Int.(NCM)


# Início do comentário Felipe
# Esta coisa deveria estar com um for para todas as usinas e aí eu teria um dado que diz se a usina tem ou não restrição ambiental
println("Vetor de Cenários: ",NCM)
deflu_3marias_vet_max = Array(df_delfu_max[1:7,3])
deflu_xingo_vet_max = Array(df_delfu_max[11:end,3])
vol_percent_3marias_max = Matrix(df_delfu_max[1:7,4:end])
vol_percent_xingo_max = Matrix(df_delfu_max[11:end,4:end])

deflu_3marias_vet_min = Array(df_deflu_min[1:2,3])
deflu_xingo_vet_min = Array(df_deflu_min[3:end,3])
vol_percent_3marias_min = Array(df_deflu_min[1:2,4])
vol_percent_xingo_min = Array(df_deflu_min[3:end,4])

n_max_faixa_xingo = length(deflu_xingo_vet_max)
n_max_faixa_3marias = length(deflu_3marias_vet_max)

# Fim comentário Felipe

# println("Número máximo de faixas: ", f)
#  println("Vetor defluencia máxima 3 Marias: ", deflu_3marias_vet_max)
#  println("Matriz defluencia máxima 3 Marias: ",vol_percent_3marias_max)
# println("Vetor de defluencia máxima Xingo ", deflu_xingo_vet_max)
# println("Matriz defluencia máxima Xingo ", vol_percent_xingo_max)

#  println("Vetor defluencia máxima 3 Marias: ", deflu_3marias_vet_min)
#  println("Matriz defluencia máxima 3 Marias: ",vol_percent_3marias_min)
#  readline()
# println("Vetor de defluencia máxima Xingo ", deflu_xingo_vet_min)
# println("Matriz defluencia máxima Xingo ", vol_percent_xingo_min)

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
@variable(modelo, 0 <=v[j=1:mes, i= 1:NH, a= 1:NCM[j]])
# ---------------- vArIÁvEIs --------------------- #  
@variable(modelo, 0 <= pt[j=1:mes, i= 1:NG, a= 1:NCM[j]]<= ptMax[i])
@variable(modelo, 0 <= ph[j=1:mes, i=1:NH,a= 1:NCM[j]]<= phMax[i])
@variable(modelo, 0 <= qh[j=1:mes, i=1:NH, a= 1:NCM[j]]<= qhMax[i])
@variable(modelo, 0 <= s[j=1:mes,1:NH,a= 1:NCM[j]])
@variable(modelo, 0 <= pd[j=1:mes])

# Comentário Felipe - 
# Aqui a definição de até quanto f vai deveria depender de i.
@variable(modelo, 0 <= u[j=1:mes, i= 1:NH, a=1:NCM[j], f= 1:n_max_faixa_xingo], Bin)
@variable(modelo, 0 <= F[j=1:mes, i=1:NH, a=1:NCM[j]] <= 1)
# ---------------- rEsTrIÇÕEs --------------------- #  
# for j = 1:mes
#     for a = 1:NCM[j]
#         for i = 1:NH
#             @constraint(modelo, ph[j, i, a] == qh[j, i, a] * ρ[i])
#         end
#     end
# end

# Equilibrio Hidrico
# for i = 1:NH
#     global  k = 0
#         k += 1 
#         for r = 1:NAj
#         if qt_mon[i] == 0
#             @constraint(modelo, v[1,i,k] .== v₀[i] .- qh[1,i,k] .- s[1,i,k] .+ CH[1,i,1])
#         else
#             @constraint(modelo, v[1,i,k] .== v₀[i] .- qh[1,i,k]  .-s[1,i,k] .+ CH[1,i,1] .+sum(qh[1,qs_mon[i,l],k]+s[1,qs_mon[i,l],k] for l in 1:qt_mon[i]))
#         end
#     end  
# end 
# for i = 1:NH
#     for j = 2:mes
#     local  k = 0
#         for a = 1:NCM[j-1]
#             for r = 1:NAj
#             k += 1 
#                 if qt_mon[i] == 0   
#                 @constraint(modelo, v[j,i,k] .== v[j-1, i, a] .- qh[j,i,k] .- s[j,i,k] .+ CH[j,i,r])
#                 else  
#                 @constraint(modelo, v[j,i,k] .== v[j-1,i, a] .- qh[j,i,k] .+ CH[j,i,r] .-s[j,i,k].+sum(qh[j,qs_mon[i,l],k]+s[j,qs_mon[i,l],k] for l in 1:qt_mon[i]))
#                 end
#             end
#         end
#     end
# end

# for j in 1:mes
#     for a in 1:NCM[j]
#         @constraint(modelo, sum(pt[j,i, a] for i in 1:NG) + sum(ph[j,i,a] for i in 1:NH) +pd[j] == D[j])
#     end
# end

# defluência 3 marias #

# Definindo a defluencia
# for f in 1:n_max_faixa_3marias
#     @constraint(modelo, F[1,2,1]== v₀[2]/vmax[2])
# end
# for f in 1:n_max_faixa_xingo
#     @constraint(modelo, F[1,7,1]== v₀[4]/vmax[4])
# end
# for j in 2:mes
#     for a in 1:NCM[j]
#         # Calcula o índice do cenário pai no estágio j-1
#         parent_a = ceil(Int, a / NAj)
#         @constraint(modelo, F[j,2,a] == v[j-1, 2, parent_a] / vmax[2]) 
#         @constraint(modelo, F[j,7,a] == v[j-1, 4, parent_a] / vmax[4]) 
#     end
# end

#definindo as defluências em função das faixas
for j in 1:mes
    for a in 1:NCM[j]
        # @constraint(modelo, sum(u[j,2,a,f] for f in 1:n_max_faixa_3marias) == 1) # Mostrar em que faixa a 3 marias está
        # @constraint(modelo, sum(u[j,7,a,f] for f in 1:n_max_faixa_xingo) == 1) # Mostrar em que faixa a xingó está


        #FAIXA 1:
        # @constraint(modelo, F[j,2,a] >= 0*u[j,2,a,1]) # Não precisa ter, pois a restriição já garante que é maior igual a zero
        @constraint(modelo, F[j,2,a] <= 0.01*vol_percent_3marias_max[1,j]*u[j,2,a,1] + (1-u[j,2,a,1]))

        for faixa in 2:n_max_faixa_3marias 
            faixa_aux = faixa-1
            while vol_percent_3marias_max[faixa_aux,j] == -1.0
                faixa_aux = faixa_aux-1
            end
            @constraint(modelo, F[j,2,a] >= 0.01*vol_percent_3marias_max[faixa_aux,j]*u[j,2,a,faixa]) #Faixa de restrição
            # println("percentfaixa: ", vol_percent_3marias_max[faixa,j])
            # readline()
            if vol_percent_3marias_max[faixa,j] == -1.0
                @constraint(modelo, u[j,2,a,faixa] == 0)
            else
                @constraint(modelo, F[j,2,a] <= 0.01*vol_percent_3marias_max[faixa,j]*u[j,2,a,faixa] + (1-u[j,2,a,faixa])) #Faixa de restrição
            end
        end
    end
end

# ---------------- FUNÇÃO OBJETIvO --------------------- #  

@objective(modelo, Min, sum(sum(sum(sum((1/NCM[j])*CVU[i]*pt[j,i,c] for i = 1:NG) for c = 1:NCM[j])  + def*pd[j]) for j = 1:mes))

print(modelo)
optimize!(modelo)


# PRINTANDO
# for j in 1:mes
#     for a in 1:NCM[j]
#         println("Faixa do mês $j 3 marias cenário $a: ", value(F[j,2,a]))
#         println("Faixa do mês $j Xingó cenário $a: ", value(F[j,7,a]))    
#     end
# end
roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU)