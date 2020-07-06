%[FM_data] = Func_fit_data_values(data,FM_params)
%uses fminsearch to fit a decaying exponential to the data;
%assume only one freq component in the trace
%uses range of data.pro supplied by FM_params.range

function [FM_data] = Func_fit_data_values_multiscan(data,axis_info,FM_params)
% work in progress
disp('Time domain fitting starting')
for sc = 1:axis_info.number_of_scans
    disp(['Started scan ' num2str(sc) ' of ' num2str(axis_info.number_of_scans)])
    for L=1:length(data.(['scan' num2str(sc)]).ac);
        d =1e9* data.(['scan' num2str(sc)]).t_out{1}(FM_params.range)'; % Changed to brace index
        FM_data.(['scan' num2str(sc)]).t = d;
        for j =1:axis_info.(['scan' num2str(sc)]).axis_pts(2);
            if (j==1)||(rem(j,10)==0)
                disp(strcat(num2str(j),'/',num2str(axis_info.(['scan' num2str(sc)]).axis_pts(2))))
            end
            for k =1:axis_info.(['scan' num2str(sc)]).axis_pts(1);
                to_fit = 1000*squeeze(data.(['scan' num2str(sc)]).pro{L}(k,j,FM_params.range));
                
                f = data.(['scan' num2str(sc)]).freq{L}(k,j);
                A = 0;
                B = 1000*data.(['scan' num2str(sc)]).f_amp{L}(k,j);
                alpha = 1;
                phi =pi/2;
                param_guess = [A  B f alpha phi]; % input parameters for fitfun_gauss: [height width centre]
                options=optimset('fminsearch');
                options = optimset(options,'Display','off','MaxFunEvals',5000);
                [pars,fval,exitflag,output]=fminsearch(@(guess)fitfun_decay_sin_with_plottest(guess,d,to_fit),param_guess,options);
                FM_data.(['scan' num2str(sc)]).A{L}(k,j) = pars(1);
                FM_data.(['scan' num2str(sc)]).amp{L}(k,j) = pars(2);
                FM_data.(['scan' num2str(sc)]).freq{L}(k,j) = pars(3);
                FM_data.(['scan' num2str(sc)]).alpha{L}(k,j) = pars(4);
                FM_data.(['scan' num2str(sc)]).phi{L}(k,j) = pars(5);
                FM_data.(['scan' num2str(sc)]).fval{L}(k,j) = fval;
                FM_data.(['scan' num2str(sc)]).exit{L}(k,j) = exitflag;
                FM_data.(['scan' num2str(sc)]).fncount{L}(k,j) = output.funcCount;
                FM_data.(['scan' num2str(sc)]).itcount{L}(k,j) = output.iterations;
                %build aray of error residuals.
                A1 = pars(1);
                B1 = pars(2);
                C1 = pars(3);
                D1 = pars(4);
                E1 = pars(5);
                fitted = A1+B1.*sin(2*pi*C1*d+E1).*exp(-D1*d);
                FM_data.(['scan' num2str(sc)]).residuals{L}(k,j,:) = to_fit - fitted;
                FM_data.(['scan' num2str(sc)]).traces_fit{L}(k,j,:) = fitted;
                FM_data.(['scan' num2str(sc)]).data_array{L}(k,j,:) =to_fit;
                
            end
        end
    end
end
disp('Time domain fitting Finished')