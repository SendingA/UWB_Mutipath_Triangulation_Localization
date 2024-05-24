function [assignment, cost] = munkres(costMat)
    % Ensure the matrix is rectangular
    [m, n] = size(costMat);
    if m > n
        costMat = [costMat, inf(m, m-n)]; % Use 'inf' to represent impossible assignments
    elseif m < n
        costMat = [costMat; inf(n-m, n)]; % Use 'inf' to represent impossible assignments
    end
    
    % Step 1: Subtract row minima
    costMat = bsxfun(@minus, costMat, min(costMat, [], 2));
    
    % Step 2: Subtract column minima
    costMat = bsxfun(@minus, costMat, min(costMat, [], 1));
    
    % Step 3: Cover all zeros with a minimum number of horizontal and vertical lines.
    coveredRows = false(m, 1);
    coveredCols = false(n, 1);
    starredZeros = false(m, n);
    primedZeros = false(m, n);
    
    % Step 4: Star each zero in the cost matrix if there is no other starred zero
    % in the same row or column.
    for i = 1:m
        for j = 1:n
            if costMat(i, j) == 0 && ~any(starredZeros(i, :)) && ~any(starredZeros(:, j))
                starredZeros(i, j) = true;
            end
        end
    end
    
    while true
        % Cover each column containing a starred zero
        coveredCols = any(starredZeros, 1);
        
        % Step 5: Cover all columns containing a starred zero. If all columns are
        % covered, the starred zeros form the minimum cost perfect matching.
        if all(coveredCols)
            break;
        end
        
        % Step 6: Find a noncovered zero and prime it. If there is no starred zero
        % in the row containing this primed zero, go to Step 7. Otherwise, cover
        % this row and uncover the column containing the starred zero.
        while true
            [zeroRow, zeroCol] = find(costMat == 0 & ~coveredRows & ~coveredCols, 1);
            if isempty([zeroRow, zeroCol])
                % Step 8: Add the minimum uncovered value to every element of each
                % covered row, and subtract it from every element of each uncovered
                % column. Return to Step 6 without altering any stars, primes, or
                % covered lines.
                minUncoveredValue = min(min(costMat(~coveredRows, ~coveredCols)));
                costMat(~coveredRows, :) = costMat(~coveredRows, :) + minUncoveredValue;
                costMat(:, coveredCols) = costMat(:, coveredCols) - minUncoveredValue;
            else
                primedZeros(zeroRow, zeroCol) = true;
                if ~any(starredZeros(zeroRow, :))
                    % Step 7: Construct a series of alternating primed and starred
                    % zeros as follows. Let Z0 represent the uncovered primed zero
                    % found in Step 6. Let Z1 denote the starred zero in the column
                    % of Z0 (if any). Let Z2 denote the primed zero in the row of Z1
                    % (there will always be one). Continue until the series terminates
                    % at a primed zero that has no starred zero in its column. Unstar
                    % each starred zero of the series, star each primed zero of the
                    % series, erase all primes and uncover every line in the matrix.
                    % Return to Step 5.
                    seq = [zeroRow, zeroCol];
                    while true
                        z1 = find(starredZeros(:, seq(end, 2)), 1);
                        if isempty(z1)
                            break;
                        else
                            seq = [seq; z1, seq(end, 2)];
                            z2 = find(primedZeros(seq(end, 1), :), 1);
                            seq = [seq; seq(end, 1), z2];
                        end
                    end
                    starredZeros(sub2ind(size(starredZeros), seq(1:2:end, 1), seq(1:2:end, 2))) = true;
                    starredZeros(sub2ind(size(starredZeros), seq(2:2:end, 1), seq(2:2:end, 2))) = false;
                    primedZeros(:) = false;
                    coveredRows(:) = false;
                    coveredCols(:) = false;
                    break;
                else
                    coveredRows(zeroRow) = true;
                    coveredCols(starredZeros(zeroRow, :)) = false;
                end
            end
        end
    end
    
    % Form the assignment matrix
    assignment = zeros(m, 1);
    [row, col] = find(starredZeros);
    for i = 1:numel(row)
        assignment(row(i)) = col(i);
    end
    
    % Compute the minimum cost
    cost = sum(costMat(sub2ind(size(costMat), row, col)));
    assignment = assignment(1:m);
end
