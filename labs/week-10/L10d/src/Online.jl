"""
    function play(model::MyBinaryWeightedMajorityAlgorithmModel, 
        data::Array{Float64,2})::Tuple{Array{Int64,2}, Array{Float64,2}}

This method plays the online learning game using the `MyBinaryWeightedMajorityAlgorithmModel` instance and the provided data. 
It returns the results of the game and the updated weights of the experts.

### Arguments
- `model::MyBinaryWeightedMajorityAlgorithmModel`: An instance of the `MyBinaryWeightedMajorityAlgorithmModel` type.
- `data::Array{Float64,2}`: A 2D array containing the data for the game.

### Returns 
- `results_array::Array{Int64,2}`: A 2D array containing the results of the game. Each row corresponds to a round, and the columns contain:
- `weights::Array{Float64,2}`: A 2D array containing the updated weights of the experts after each round.
"""
function play(model::MyBinaryWeightedMajorityAlgorithmModel, 
    data::Array{Float64,2})

    # initialize -
    n = model.n; # how many experts do we have?
    T = model.T; # how many rounds do we play?
    ϵ = model.ϵ; # learning rate
    weights = model.weights; # weights of the experts
    expert = model.expert; # expert function
    adversary = model.adversary; # adversary function
    results_array = zeros(Int64, T, 3+n); # aggregator predictions

    # main simulation loop -
    for t ∈ 1:T
        
        # query the experts -
        expert_predictions = zeros(Int64, n);
        for i ∈ 1:n
            expert_predictions[i] = expert(i, t, data); # call the expert function, returns a prediction for expert i at time t-1
        end

        # store the expert predictions -
        for i ∈ 1:n
            results_array[t, i] = expert_predictions[i];
        end

        # compute the weighted prediction -
        weight_down_vote = findall(x-> x == -1, expert_predictions) |> i-> sum(weights[t, i]);
        weight_up_vote = findall(x-> x == 1, expert_predictions) |> i-> sum(weights[t, i]);
        aggregator_prediction = (weight_up_vote > weight_down_vote) ? 1 : -1;
        results_array[t,n+1] = aggregator_prediction; # store the aggregator prediction

        # query the adversary -
        actual = adversary(t, data); # call the adversary function, returns the actual outcome at time t
        results_array[t, n+2] = actual; # store the adversary outcome

        # compute the aggregator loss -
        results_array[t, end] = (aggregator_prediction == actual) ? 0 : 1;

        # compute the loss for each expert -
        loss = zeros(Float64, n);
        for i ∈ 1:n
            loss[i] = (expert_predictions[i] == actual) ? 0.0 : 1.0; # change the sign of the loss, to update the weights
        end

        # update the weights -
        for i ∈ 1:n
            weights[t+1, i] = weights[t, i]*(1 - ϵ*loss[i]);
        end
    end

    # return -
    return (results_array, weights);
end

"""
    function play(model::MyTwoPersonZeroSumGameModel)::Tuple{Array{Int64,2}, Array{Float64,2}}

This method plays the two-person zero-sum game using the `MyTwoPersonZeroSumGameModel` instance. 
It returns the results of the game and the updated weights of the experts.

### Arguments
- `model::MyTwoPersonZeroSumGameModel`: An instance of the `MyTwoPersonZeroSumGameModel` type.

### Returns 
- `results_array::Array{Int64,2}`: A 2D array containing the results of the game. Each row corresponds to a round, and the columns contain:
    - The first column is the action of the row player (aggregator).
    - The second column is the action of the column player (adversary).
- `weights::Array{Float64,2}`: A 2D array containing the updated weights of the experts after each round.
"""
function play(model::MyTwoPersonZeroSumGameModel)

    # initialize -
    n = model.n; # how many actions do we have?
    T = model.T; # how many rounds do we play?
    η = model.ϵ; # learning rate
    weights = model.weights; # weights of the actions (row player)
    M = model.payoffmatrix; # payoff matrix
    L = -M; # loss matrix
    results_array = zeros(Int64, T, 2); # store actions: [row_player, column_player]

    # main simulation loop -
    for t ∈ 1:T
        
        # Step 1: Compute normalization factor
        Φ = sum(weights[t, :]);
        
        # Step 2: Row player computes strategy (probability distribution over actions)
        p = weights[t, :] / Φ;
        
        # Row player samples an action from the categorical distribution
        d = Categorical(p);
        i_star = rand(d); # row player's action
        results_array[t, 1] = i_star;
        
        # Step 3: Column player computes best response
        # Column player minimizes row player's expected payoff: argmin_j p^T M e_j
        expected_payoffs = M' * p; # compute p^T M for each column
        j_star = argmin(expected_payoffs); # column player chooses action that minimizes row player's payoff
        results_array[t, 2] = j_star;
        
        # Compute loss vector for row player: ℓ = L * q, where q = e_j
        loss = L[:, j_star]; # loss vector (column j of L)
        
        # Step 4: Update weights using multiplicative update rule
        # w_i^(t+1) = w_i^(t) * exp(-η * ℓ_i^(t))
        if t < T # don't update weights on the last round
            for i ∈ 1:n
                weights[t+1, i] = weights[t, i] * exp(-η * loss[i]);
            end
        end
    end

    # return -
    return (results_array, weights);
end