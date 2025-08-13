using JuMP, Gurobi

# Dados do problema
VI =1300
NT = 2
NH = 2
N = 2 # numero de meses
NAj = 2 
cen_mes = N^NAj
NCM = [1,2,4,8] # numero de cenarios por mes = n^mes
D = [200, 300, 400]
TM = 1000
HM = 1500
VM = 2000
c = [10, 20]
π = [0.5, 0.5]
ρ = [0.1, 0.2]


# struct Hidroeletrica
#     nome::String
#     codUsina::Int32
#     jusante::Int64
#     phMax::Float64
#     vUtil::Float64
#     ρ::Float64
#     qMax::Float64
#     v₀::Float64
#     cenario::Int64
# end

# struct Noh
#     usina::Hidroeletrica
#     filhos::Vector{Noh}
# end

# function criarRaiz(usina::Hidroeletrica)::Noh
#     noh = Noh(usina, [])
#     return noh
# end

# function adicionarFilho(raiz::Noh, filho::Noh)
#     append!(raiz.filhos, filho) #adiciona elementos a um vetor
# end

# function achatUsina(noh::Noh)::Hidroeletrica
#     return noh.usina
# end

# function achaFilhos(noh::Noh)::Vector{Noh}
#     return noh.filhos
# end

# function percorrerArvore(raiz::Noh)
#     println(getUsina(raiz).nome)

#     for filho ∈ acha Filhos(raiz)
#         percorrerArvore(filho)
#     end
# end


modelo = Model(Gurobi.Optimizer)

# Variáveis de decisão
@variable(modelo, 0 <= T[i=1:N, j=1:NT, a=1:NAj] <= TM)
@variable(modelo, 0 <= H[i=1:N, j=1:NH, a=1:NAj] <= HM)
@variable(modelo, 0 <= V[i=1:N, j=1:NH, a=1:NAj] <= VM)
@variable(modelo, 0 <= S[i=1:N, j=1:NH, a=1:NAj])
@variable(modelo, 0 <= CH[i=1:N, j=1:NH, a=1:NAj])


# Função Objetivo
@objective(modelo, Min, sum(c[i] * sum(π[a] * T[i, j, a] for a = 1:NAj) for i = 1:N, j = 1:NT))


# Equilibrio Hidrico
cont = 0
for i  ∈ 1:N
    for j ∈ 1:NH
        for a ∈ 1:NCM[i-1]
            for r ∈ 1:NAj
                cont += 1
                if i == 1
                @constraint(modelo, V[i,j,cont] .== VI .- H[i,j,cont] .- S[i,j,cont] .+ CH[i,j,r])
                else
                @constraint(modelo, V[i,j,cont] .== V[i-1, j, a] .- H[i,j,cont] .- S[i,j,cont] .+ CH[i,j,r])
                end
            end
        end
    end
end

# Restrições de Demanda
for j = 1:N
    @constraint(modelo, sum(T[j, i, a] for i = 1:NT, a = 1:NAj) + sum(ρ[i] * H[j, i, a] for i = 1:NH, a = 1:NAj) == D[j])
end

# Resolver o modelo
optimize!(modelo)

# Verificar a solução
if termination_status(modelo) == MOI.OPTIMAL
    for j = 1:N
        println("Estágio $j:")
        for i = 1:NT, a = 1:NAj, s = 1:NAj
            println("Produção da usina termoelétrica $i no cenário $a no estágio $j: ", value(T[i, j, a]))
        end
        for i = 1:NH, a = 1:NAj, s = 1:NAj
            println("Produção da usina hidroelétrica $i no cenário $a no estágio $j: ", value(H[i, j, a]))
        end
    end
    println("Custo total: ", objective_value(modelo))
else
    println("O modelo não encontrou uma solução ótima.")
end

