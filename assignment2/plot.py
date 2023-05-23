# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="processed_iperf3.log"
label='label'
xlabel = 'time'
ylabel = 'Bandwidth [Mbit/s]'
title='Bandwidth vs time, iperf3'
fig_name='iperf3.png'
bins=100 #adjust the number of bins to your plot


t = np.loadtxt(filename, dtype="float")
plt.plot(np.linspace(0,10, len(t)), t, label=label)  # Plot some data on the (implicit) axes.
#Comment the line above and uncomment the line below to plot a CDF
#plt.hist(t, bins, density=True, histtype='step', cumulative=True, label=label)
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
