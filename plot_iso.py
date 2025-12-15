import matplotlib.pyplot as plt
import pandas as pd
import json
import os,re
import numpy as np

#chalk_dir ="./data-cliff-stability_no_stress/"
chalk_dir ="./data-cliff-stability/"
#chalk_dir = "/nobackup/rmvn14/ham-chalk-conv-fbar/"
output_regex = re.compile("data.*json")
output_list = list(filter(output_regex.match,os.listdir(chalk_dir)))
output_list.sort()
print(output_list)

h = 20

x = []
y = []
t = []
plot_cliff = False
data_stable = []
tau = 1e4
h = 20
float_point = ( 918 / 1028)
for i,out in enumerate(output_list):
    #output_dir = chalk_dir + "./{}/".format(out)
    with open(chalk_dir+out) as f:
        js = json.load(f)
        height = float(js["HEIGHT"])
        floatation = float(js["FLOATATION"])
        time = min(float(js["TIME"])/tau,100)
        stable = js["STABLE"]==True

        #lw = round((height*floatation)/h)*h
        lw=height*floatation*float_point
        #lw=round((lw)/h)*h
        x.append(height)
        if plot_cliff:
            y.append(height - lw)
        else:
            y.append(lw)
        t.append(time)
        data_stable.append(stable)

x = np.array(x)
y = np.array(y)
t = np.array(t)
data_stable = np.array(data_stable)
# plt.scatter(x[data_stable==True],y[data_stable==True],c=t[data_stable==True])
#plt.scatter(x[data_stable==True],y[data_stable==True],c=t[data_stable==True])
#plt.tricontour(x,y,t)
cmin = t.min()
cmax = t.max()
dst = data_stable==True
plt.scatter(x[dst],y[dst],c=t[dst])
plt.clim(cmin,cmax)
dsf = data_stable==False
plt.scatter(x[dsf],y[dsf],c=t[dsf],marker="x")
plt.clim(cmin,cmax)
plt.xlabel("Height (m)")
#plt.ylabel("Water height (m)")
if plot_cliff:
    plt.ylabel("Cliff height (m)")
else:
    plt.ylabel("Water height (m)")
plt.scatter([],[],label="Stable")
plt.scatter([],[],marker="x",label="Unstable")
plt.legend()
plt.colorbar()
plt.show()
