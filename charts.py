import pandas as pd
import matplotlib.pyplot as plt

# read the CSV data
data = pd.read_csv('benchmark_results.csv')

# plot execution times (client-side)
plt.figure(figsize=(12, 6))
data.plot(kind='bar', x='Operation', y='Time (ms)', legend=False, ax=plt.gca())
plt.title('Operation Execution Times (Client-Side)')
plt.ylabel('Time (ms)')
plt.tight_layout()
plt.savefig('execution_times.png')
plt.show()

# plot gas consumption
plt.figure(figsize=(12, 6))
data.plot(kind='bar', x='Operation', y='Gas', legend=False, ax=plt.gca())
plt.title('Gas Consumption per Operation')
plt.ylabel('Gas')
plt.tight_layout()
plt.savefig('gas_consumption.png')
plt.show()

# plot CPU usage

# plot memory usage
