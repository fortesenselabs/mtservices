def calculate_final_amount(starting_amount, profit_rate, num_days):
    principal = starting_amount

    for _ in range(num_days):
        principal += principal * profit_rate

    return principal


starting_amount = 10.0  # Initial principal amount
profit_rate = 0.1  # 10% profit rate per day
num_days = 30

final_amount = calculate_final_amount(starting_amount, profit_rate, num_days)
print(f"The final amount after {num_days} days is: ${final_amount:.2f}")
