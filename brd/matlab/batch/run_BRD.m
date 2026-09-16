function run_t2inversion_for_plot()
% 批处理 decay curves same density.xlsx 的所有 sheet，
% 使用珺文反演代码核心（AmplitudeSample + brd1）生成可绘图 T2 谱。
%
% 输出 Excel 每个 sheet 两列：
%   Time_ms, Amplitude
% 可被 plot_nmr_t2_1x2.py 直接读取（其列匹配支持回退到前两列）。

    cd("C:\Users\imgw\python\research\bnmr_mcmc-main\T2反演方法验证\珺文反演代码")
    addpath(genpath('.'))

    %% ---------------- 配置 ----------------
    inputXlsx = "C:\Users\imgw\python\research\bnmr_mcmc-main\T2反演方法验证\nidhal数据代码\decay curves same density.xlsx";
    outputXlsx = "C:\Users\imgw\python\research\bnmr_mcmc-main\T2反演方法验证\nidhal数据代码\peak distrib junwen_brd.xlsx";

    % 珺文反演代码目录（含 AmplitudeSample.m / brd1.p）
    codeDir = "C:\Users\imgw\python\research\bnmr_mcmc-main\T2反演方法验证\珺文反演代码";

    % 用户指定参数
    NUM_BINS  = 200;
    REG_PARAM = 1;
    T2_MIN_MS = 1e-2;
    T2_MAX_MS = 1e5;

    %% ---------------- 环境检查 ----------------
    addpath(codeDir);
    addpath(genpath(codeDir));

    if exist('AmplitudeSample', 'file') == 0
        error('找不到 AmplitudeSample 函数（AmplitudeSample.m）。请确认其在路径中。codeDir=%s', codeDir);
    end
    if exist('brd1', 'file') == 0
        error('找不到 brd1 函数（brd1.p / brd1.m）。请确认其在路径中。codeDir=%s', codeDir);
    end

    fprintf('Using AmplitudeSample: %s\n', which('AmplitudeSample'));
    fprintf('Using brd1: %s\n', which('brd1'));

    if ~isfile(inputXlsx)
        error('找不到输入文件: %s', inputXlsx);
    end

    T2_ms = logspace(log10(T2_MIN_MS), log10(T2_MAX_MS), NUM_BINS).';

    sheets = sheetnames(inputXlsx);
    if isempty(sheets)
        error('输入Excel没有sheet: %s', inputXlsx);
    end

    % 覆盖输出文件（避免旧 sheet 残留）
    if isfile(outputXlsx)
        delete(outputXlsx);
    end

    %% ---------------- 批处理 ----------------
    for i = 1:numel(sheets)
        sh = sheets{i};
        T = readtable(inputXlsx, 'Sheet', sh, 'VariableNamingRule', 'preserve');

        [t_ms, y] = extract_decay_xy(T);

        valid = isfinite(t_ms) & isfinite(y) & (t_ms > 0);
        t_ms = t_ms(valid);
        y    = y(valid);

        [t_ms, idx] = sort(t_ms, 'ascend');
        y = y(idx);

        if numel(t_ms) < 10
            error("sheet '%s' 有效点太少，无法反演。", sh);
        end

        % 与 T2inversion.m 一致的预采样思路：先做对数采样
        sampleNumber = min(4500, numel(t_ms));
        [pick_t, pick_y] = AmplitudeSample(t_ms(:), y(:), sampleNumber, 0);
        pick_t = pick_t(:);
        pick_y = pick_y(:);

        % 与 T2inversion.m 同结构核矩阵：exp(-t/T2)
        K = exp(-pick_t * (T2_ms'.^(-1)));

        % 调用同一反演器 brd1，正则参数由 REG_PARAM 指定
        amp = brd1(K, pick_y, REG_PARAM);
        amp = amp(:);

        % 容错：确保和 T2_ms 行数一致
        if numel(amp) ~= NUM_BINS
            if numel(amp) > NUM_BINS
                amp = amp(1:NUM_BINS);
            else
                amp = [amp; zeros(NUM_BINS - numel(amp), 1)];
            end
        end

        outTbl = table(T2_ms, amp, 'VariableNames', {'Time_ms', 'Amplitude'});
        writetable(outTbl, outputXlsx, 'Sheet', sh);

        fprintf('Processed sheet: %s (n=%d)\n', sh, height(outTbl));
    end

    fprintf('\nDone.\nInput : %s\nOutput: %s\n', inputXlsx, outputXlsx);
end


function [t, y] = extract_decay_xy(T)
% 优先按常见列名找 Time/Peak；找不到则回退前两列。
    varNames = string(T.Properties.VariableNames);
    normNames = lower(regexprep(varNames, '[^a-z0-9]', ''));

    tCand = ["time", "echotime", "timems", "t"];
    yCand = ["peak", "amplitude", "signal", "intensity"];

    tIdx = find_col_index(normNames, tCand, 1);
    yIdx = find_col_index(normNames, yCand, 2);

    t = to_numeric_col(T{:, tIdx});
    y = to_numeric_col(T{:, yIdx});
end


function idx = find_col_index(normNames, candidates, fallbackIdx)
    idx = [];
    for c = 1:numel(candidates)
        k = find(normNames == candidates(c), 1, 'first');
        if ~isempty(k)
            idx = k;
            return;
        end
    end

    if fallbackIdx <= numel(normNames)
        idx = fallbackIdx;
    else
        error('找不到需要的列，且 fallback 超出范围。');
    end
end


function x = to_numeric_col(col)
    if isnumeric(col)
        x = double(col);
        return;
    end

    if iscell(col)
        x = nan(size(col));
        for i = 1:numel(col)
            v = col{i};
            if isnumeric(v) && isscalar(v) && isfinite(v)
                x(i) = double(v);
            elseif isstring(v) || ischar(v)
                x(i) = str2double(string(v));
            else
                x(i) = NaN;
            end
        end
        return;
    end

    if isstring(col) || ischar(col)
        x = str2double(string(col));
        return;
    end

    x = nan(size(col));
end
