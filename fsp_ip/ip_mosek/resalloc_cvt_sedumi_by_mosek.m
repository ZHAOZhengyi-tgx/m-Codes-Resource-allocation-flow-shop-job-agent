function sedumi_form = resalloc_cvt_sedumi_by_mosek(mosek_form)

MatrixA = mosek_form.a;
B_LowConstr = mosek_form.blc;
B_UppConstr = mosek_form.buc;
C_Vector = mosek_form.c;
B_LowBoundX = mosek_form.blx;
B_UppBoundX = mosek_form.bux;

[nTotal_constr, nTotal_var] = size(MatrixA);

iSlack_var_base_index = nTotal_var;
nTotalConstrSedumi = nTotal_constr;
nTotalVarSedumi = nTotal_var;
%afRHS = sparse()
matSedumi = sparse([], [], [], nTotal_constr, nTotal_var, 0);

%% converting the constraints
for ii = 1:1:nTotal_constr
    matSedumi(ii, 1:nTotal_var) = MatrixA(ii, :);
    if B_LowConstr(ii) == B_UppConstr(ii)
        afRHS(ii) = B_LowConstr(ii);
    elseif B_LowConstr(ii) == -inf
        afRHS(ii) = B_UppConstr(ii);
        nTotalVarSedumi = nTotalVarSedumi + 1;
        matSedumi(ii, nTotalVarSedumi) = 1;  %% add one slack variable, by addition
    elseif B_UppConstr(ii) == inf
        afRHS(ii) = B_LowConstr(ii);
        nTotalVarSedumi = nTotalVarSedumi + 1;
        matSedumi(ii, nTotalVarSedumi) = -1;  %% add one slack variable, by subtraction
    else
        afRHS(ii) = B_UppConstr(ii);
        nTotalVarSedumi = nTotalVarSedumi + 1;
        matSedumi(ii, nTotalVarSedumi) = 1;  %% add one slack variable, by addition
        
        %% add one more constraints
        nTotalConstrSedumi = nTotalConstrSedumi + 1;
        nTotalVarSedumi = nTotalVarSedumi + 1;
        matSedumi(nTotalConstrSedumi, 1:nTotal_var) = MatrixA(ii, :);
        afRHS(nTotalConstrSedumi) = B_LowConstr(ii);
        matSedumi(nTotalConstrSedumi, nTotalVarSedumi) = -1;  %% add one slack variable, by subtraction
    end
end

%% converting the variables' bounds
for ii = 1:1:nTotal_var
    if B_LowBoundX(ii) > 0
        nTotalConstrSedumi = nTotalConstrSedumi + 1;
        nTotalVarSedumi = nTotalVarSedumi + 1;
        afRHS(nTotalConstrSedumi) = B_LowBoundX(ii);
        matSedumi(nTotalConstrSedumi, ii) = 1;
        matSedumi(nTotalConstrSedumi, nTotalVarSedumi) = -1;
    end
end
nTotalConstrSedumi
for ii = 1:1:nTotal_var
    if B_UppBoundX(ii) < 0
        error('upper bound of variables cannot < 0')
    elseif B_UppBoundX(ii) == 0
        nTotalConstrSedumi = nTotalConstrSedumi + 1;
        afRHS(nTotalConstrSedumi) = 0;
        matSedumi(nTotalConstrSedumi, ii) = 1;
    elseif B_UppBoundX(ii) == inf
    else
        nTotalConstrSedumi = nTotalConstrSedumi + 1;
        nTotalVarSedumi = nTotalVarSedumi + 1;
        afRHS(nTotalConstrSedumi) = B_UppBoundX(ii);
        matSedumi(nTotalConstrSedumi, ii) = 1;
        matSedumi(nTotalConstrSedumi, nTotalVarSedumi) = 1;
    end
end

%%%
%%% First ptn_info.dim_feature variables are free
K.f = 0;
%%% non-negative variables
K.l = nTotalVarSedumi;
%%% following 1 + ptn_info.dim_feature + ptn_info.dim_feature * (ptn_info.dim_feature + 1)/2 variables subject to a quadratic cone
K.q = 0;

aVectorCSedumi = sparse([], [], [], nTotalVarSedumi, 1, 0);
aVectorCSedumi(1:nTotal_var) = C_Vector;

sedumi_form.A = matSedumi;
sedumi_form.b = afRHS;
sedumi_form.c = aVectorCSedumi;
sedumi_form.K = K;
