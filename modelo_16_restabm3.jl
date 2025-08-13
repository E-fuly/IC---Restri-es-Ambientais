#####################################
# Modelo: Estudando a influência de #
#restriçõesoambientaisem modelos    #
#para determinar o preço da energia #
#elétrica parte meses_no_ano        #
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
df_deflu_max = CSV.read("D:/IC/Dados/Dados Kenny/RestricoesSeguranca_defluencia_maxima.csv", DataFrame)
df_deflu_min = CSV.read("D:/IC/Dados/Dados Kenny/RestricoesSeguranca_defluencia_minima.csv",DataFrame)

#============================================================================================================================================================================================#
# ---------------- DADOS --------------------- #
v₀ = Array(df_hidro[:,9]) #Volume Inicial
vmax = Array(df_hidro[:,6]) #Volume máximo
ptMax = Array(df_termo[:,4]) #Pot máx termo
phMax = Array(df_hidro[:,5]) #Pot máx hidro
qhMax =Array(df_hidro[:,8]) #Turb max hidro
ρ = Array(df_hidro[:,7]) # prod max hidro
NH = 7
NG = 5
NAj = 1
d = Array(df_demanda[:,2:13])
anos = 1
meses_no_ano = 3
mes = meses_no_ano * anos


CVU = Array(df_termo[:,5])
def = 7643.82

qt_mon = [0,1,0,2,1,1,1] # Quantidade de usinas que ela recebe água
qs_mon = [0 0 0 0 0 0 0; 1 0 0 0 0 0 0; 0 0 0 0 0 0 0; 2 3 0 0 0 0 0; 4 0 0 0 0 0 0; 5 0 0 0 0 0 0; 6 0 0 0 0 0 0] # De quem ela recebe água
ref = [-1,2,-1,-1,-1,-1,4] # Referência de defluência -> restrições ambientais

# == Definindo quantas usinas tem restrições ambientais -> para achar os parâmetros que multiplica: quantidade máxima/min de água que sair e porcentagem de volume que define a faixa == #
qtd_rest_amb = 0
for i in 1:NH
    if ref[i] > 0
        global qtd_rest_amb = qtd_rest_amb + 1
    end
end

## ===== Definindo os parâmetros de forma geral ======#
num_grande = 20
deflu_max = Matrix(df_deflu_max[:,:])
deflu_min = Matrix(df_deflu_min[:,:])

k_max = size(deflu_max, 1)
num_faixa = zeros(qtd_rest_amb,1)

# == Volume máximo que sai == #
vol_deflu_max = zeros(qtd_rest_amb,num_grande)
i = 1; j = 1; k = 1;
aux = deflu_max[1,1]
while i <= qtd_rest_amb
    if deflu_max[k,1] == aux
        vol_deflu_max[i,j] = deflu_max[k,3]
        j = j + 1
    else
        num_faixa[i] = j-1
        i = i +1
        aux = deflu_max[k,1]
        vol_deflu_max[i,1] = deflu_max[k,3]
        j = 2
    end
    k = k+1
    if k > k_max
        i = i+1
    end
end

# == Percentual que define a faixa que sai == #
percent_vol_deflu_max = zeros(num_grande, mes, qtd_rest_amb)
i = 1; j = 1; k = 1;
aux = deflu_max[1,1] 
while i <= qtd_rest_amb
    if deflu_max[k,1] == aux
        for h in 1:mes
            percent_vol_deflu_max[j,h,i] = deflu_max[k,3+h]
        end
        j = j + 1
    else
        num_faixa[i] = j-1
        i = i +1
        aux = deflu_max[k,1]
        for h in 1:mes
            percent_vol_deflu_max[1,h,i] = deflu_max[k,3+h]
        end
        j = 2
    end
    k = k+1
    if k > k_max
        i = i+1
    end
end

# == Volume minima que sai == #
vol_deflu_min = zeros(qtd_rest_amb,qtd_rest_amb)
i = 1; j = 1; k = 1;
aux = deflu_min[1,1] 
while i <= qtd_rest_amb
    if deflu_min[k,1] == aux
        vol_deflu_min[i,j] =  deflu_min[k,3]
        j = j + 1
    else
        i = i + 1
        aux = deflu_min[k,1]         
        vol_deflu_min[i,1] = deflu_min[k,3]
    end
end

max_faixas = maximum(num_faixa)

# == Matriz de chuva == #
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
println("Vetor de Cenários: ",NCM)
#============================================================================================================================================================================================#

# ---------------- # MODELO # --------------------- #
function roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU) 
end   
modelo = Model(Gurobi.Optimizer)

## ===== Replicando chuva e demanda para mais de um ano -> cópia por falta de dados ====== ##
# == Chuva == #
CH = zeros(mes,NH,NAj)
for z in 0:anos-1
    CH[z*meses_no_ano+1:(z+1)*meses_no_ano, :, :] = ch
end

# == Demanda == #
D = zeros(mes)
for z in 0:anos-1
    D[z*meses_no_ano+1:(z+1)*meses_no_ano] = d[1:meses_no_ano]
 end

#============================================================================================================================================================================================#
# ---------------- Variáveis de Estado --------------------- #  
@variable(modelo, 0 <=v[j=1:mes, i= 1:NH, a= 1:NCM[j]])
# ---------------- Variáveis --------------------- #  
@variable(modelo, 0 <= pt[j=1:mes, i= 1:NG, a= 1:NCM[j]]<= ptMax[i]) #prod termicas
@variable(modelo, 0 <= ph[j=1:mes, i=1:NH,a= 1:NCM[j]]<= phMax[i]) #prod hidro
@variable(modelo, 0 <= qh[j=1:mes, i=1:NH, a= 1:NCM[j]]<= qhMax[i]) # turb hidro
@variable(modelo, 0 <= s[j=1:mes,1:NH,a= 1:NCM[j]]) # vertimento
@variable(modelo, 0 <= pd[j=1:mes, a=1:NCM[j]]) #produ de deficit

# ---------------- Variáveis de restrições ambientais --------------------- #  

@variable(modelo, u[j=1:mes, i=1:NH, a=1:NCM[j], f=1:max_faixas], Bin)
@variable(modelo, 0 <= F[j=1:mes, i=1:NH, a=1:NCM[j]] <= 1)

#============================================================================================================================================================================================#
# ---------------- Restrições --------------------- #  

## ===== Relação Produção vs Turbinamento ===== ##

for j = 1:mes
    for a = 1:NCM[j]
        for i = 1:NH
            @constraint(modelo, ph[j, i, a] == qh[j, i, a] * ρ[i])
        end
    end
end

## ===== Equilibrio Hidrico ===== ##
# == Mês 1 == #
for i = 1:NH
    for a = 1:NAj
        if qt_mon[i] == 0
            @constraint(modelo, v[1,i,a] .== v₀[i] .- qh[1,i,a] .- s[1,i,a] .+ CH[1,i,a]) # Quando não há vertimento de água
        else
            @constraint(modelo, v[1,i,a] .== v₀[i] .- qh[1,i,a]  .-s[1,i,a] .+ CH[1,i,a] .+sum(qh[1,qs_mon[i,l],a]+s[1,qs_mon[i,l],a] for l in 1:qt_mon[i])) # Quando há vertimento de água
        end
    end  
end 

# == Demais meses == #
for i = 1:NH
    for j = 2:mes
    local  a = 0
        for s_a = 1:NCM[j-1]
            for r = 1:NAj
            a += 1 
                if qt_mon[i] == 0   
                @constraint(modelo, v[j,i,a] .== v[j-1, i, s_a] .- qh[j,i,a] .- s[j,i,a] .+ CH[j,i,r]) # Quando não há vertimento de água
                else  
                @constraint(modelo, v[j,i,a] .== v[j-1,i, s_a] .- qh[j,i,a] .+ CH[j,i,r] .-s[j,i,a].+sum(qh[j,qs_mon[i,l],a]+s[j,qs_mon[i,l],a] for l in 1:qt_mon[i])) # Quando há vertimento de água
                end
            end
        end
    end
end

## ===== Demanda ===== ##
for j in 1:mes
    for a in 1:NCM[j]
        @constraint(modelo, sum(pt[j,i, a] for i in 1:NG) + sum(ph[j,i,a] for i in 1:NH) +pd[j,a] == D[j])
    end
end


## ===== Definindo a defluencia ===== ##
local g = 0
for i in 1:NH
    if ref[i] > 0
        g += 1
        @constraint(modelo, F[1,i,1] == v₀[ref[i]]/vmax[ref[i]])
        for j in 2:mes
            for a in 1:NCM[j]
                s_a = ceil(Int, a / NAj) #Calcula o índice do cenário pai no estágio j-1 -> abordagem contrária a de cima - momentos diferentes == lógicas diferentes
                @constraint(modelo, F[j,i,a] == v[j-1, ref[i], s_a] / vmax[ref[i]]) #Define a faixa de acordo com os volumes

                for f in (Int(num_faixa[g])+1):max_faixas
                    @constraint(modelo, u[j,i,a,f] == 0) #Faz com que as faixas não existam sejam de fato zero.
                end

                # == Unicidade das faixas == #
                @constraint(modelo, sum(u[j,i,a,f] for f in 1:Int(num_faixa[g])) == 1)
                
                # == Calculando qual a porcentagem de água em que a primeira faixa se encontra -> definição de em qual faixa ela se encontra == #
                @constraint(modelo, F[j,i,a] >= 0*u[j,i,a,1]) # Não precisa ter, pois a restrição já garante que é maior igual a zero -> mative por questões de vizualização
                @constraint(modelo, F[j,i,a] <= 0.01*percent_vol_deflu_max[1,j,g]*u[j,i,a,1] + (1-u[j,i,a,1]))

                # == Calculando a defluência máxima e mínima na primeira faixa == #
                @constraint(modelo, qh[j,i,a]+s[j,i,a] >= u[j,i,a,1]*vol_deflu_min[g,1])
                @constraint(modelo, qh[j,i,a]+s[j,i,a] <= u[j,i,a,1]*vol_deflu_max[g,1]+(qhMax[ref[i]]+vmax[ref[i]])*(1-u[j,i,a,1]))

                
                for faixa in 2:num_faixa[i]
                    # == Calculando qual a porcentagem de água das demais faixas -> definição de em qual faixa ela se encontra == #
                    faixa_aux = faixa-1
                    while percent_vol_deflu_max[faixa_aux,j,g] == -1.0 # Evita as faixas que são iguais a "-1" e pula para a próxima
                        faixa_aux = faixa_aux-1
                    end
                    @constraint(modelo,F[j,i,a] >= 0.01*percent_vol_deflu_max[faixa_aux,j,g]*u[j,i,a,faixa]) 
            
                    if percent_vol_deflu_max[faixa_aux,j,g] == -1.0
                        @constraint(modelo, u[j,i,a,faixa] == 0)
                    else
                        @constraint(modelo, F[j,i,a] <= 0.01*percent_vol_deflu_max[faixa,j,g]*u[j,i,a,faixa] + (1-u[j,i,a,faixa])) 
                    end
                    
                    # == Calculando a defluência máxima e mínima das demais faixas ==#
                    @constraint(modelo, qh[j,i,a]+s[j,i,a] >= u[j,i,a,faixa]*vol_deflu_min[g,2])
                    @constraint(modelo, qh[j,i,a]+s[j,i,a] <= u[j,i,a,faixa]*vol_deflu_max[g,faixa]+(qhMax[ref[i]]+vmax[ref[i]])*(1-u[j,i,a,faixa]))
                end
            end
        end
    end
end

#======================================================================================================================================================#
# ---------------- FUNÇÃO OBJETIvO --------------------- #  

@objective(modelo, Min, sum(sum(sum(sum((1/NCM[j])*CVU[i]*pt[j,i,a] for i = 1:NG) for c = 1:NCM[j])  + (def*pd[j,a]) for a = 1:NCM[j]) for j = 1:mes))

print(modelo)
optimize!(modelo)

roda_modelo(v₀,vmax,ptMax,phMax,qhMax,ρ,NH,NG,mes,ch,CVU)
