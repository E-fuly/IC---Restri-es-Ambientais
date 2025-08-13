using JuMP
using Gurobi
using LinearAlgebra

VI = 1300
NH = 2
NT = 2
TM = 1000
HM= 1500
VM= 2000
meses = 3
d = [200, 300, 400]
NAj = 2
NCM = [1,2,4,8]
# --------- MODELO ------------ #

modelo = Model(Gurobi.Optimizer)

#--------------------------- VARIÁVEIS ---------------------------------- #   
    @variable(modelo, 0 <= t[j=1:meses, i= 1:NT,k=1:NAj]<= TM)
    @variable(modelo, 0 <= h[j=1:meses, i= 1:NH,k=1:NAj]<=HM)
    @variable(modelo, 0 <= v[j=1:meses, i= 1:NH,k=1:NAj]<=VM)
    @variable(modelo, 0 <= s[j=1:meses, i= 1:NH,k=1:NAj])
    @variable(modelo, 0 <= ch[j=1:meses, i= 1:NH,k=1:NAj])

# -------------------------- RESTRIÇÕES --------------------------------- #
for j = 1:meses, k = 1:NAj, a= 1:NCM[j-1]
    if j ==1
    @constraint(modelo,sum(t[j, i= 1:NT,k])+ sum(h[j, i= 1:NH,k])==d[j])
    else
    @constraint(modelo,sum(t[j, i= 1:NT,k,a])+ sum(h[j, i= 1:NH,k,a])==d[j])
    end
end
k =0
for j = 1:meses, i=1NH 
     for r = 1:NAj
            k = k+1
        if j ==1
            @constraint(modelo,v[j,i,k] .== VI .-h[i,j,k].-s[i,j,k].+ch[i,j,r])
        else
            for  a= 1:NCM[j-1]
            @constraint(modelo,v[j,i,k] .== v[j-1, i,a].-h[i,j,k].-s[i,j,k].+ch[i,j,r])
            end
        end 
    end
end

for j = 1:meses, i= 1:NT, k = 1:NAj
    @objective(modelo,Min,sum(NCM[i]*sum(t[j,i,k])))
end

optimize!(modelo)