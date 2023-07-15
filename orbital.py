import numpy as np
from matplotlib import pyplot as plt

class Spacecraft:
    def __init__(self,init_pos,init_vel,mass,deltaV):
        self.init_pos = np.array(init_pos)
        self.init_vel = np.array(init_vel)
        self.mass = mass
        self.deltaV = deltaV
        
class Moon:
    def __init__(self,mass,alt):
        self.mass = mass
        self.alt = alt


prop_time = 1000000
int_time = 0.1
M = 5.792 * 10**24 #kg
G = 6.67 * 10**-11 #N*m^2/kg^2
craft1 = Spacecraft(init_pos = [92000000,0,0],init_vel = [0,9150,0],mass = 1,deltaV = 1)
moon = Moon(mass = 7.347*10**22, alt = 405500000)

# Initialize array as n by 4 (t,x,y,z), units in meters and seconds
n = int(prop_time/int_time)
trajectory = np.zeros((n,3))

ri = craft1.init_pos
vi = craft1.init_vel
for i in range(0,n):
    rj = np.array([-moon.alt,0,0])
    accel = -G*((M/(np.linalg.norm(ri)**3))*ri + (moon.mass/(np.linalg.norm(ri - rj)**3))*(ri - rj))
    ri = ri + vi*int_time
    vi = vi + accel*int_time
    trajectory[i,:] = ri
  
fig = plt.figure(figsize=(100,100))
ax = fig.add_subplot(111, projection='3d')
ax.plot(trajectory[:,0], trajectory[:,1], trajectory[:,2],color='white',linewidth='5')

u, v = np.mgrid[0:2*np.pi:20j, 0:np.pi:10j]
x = 6369784*np.cos(u)*np.sin(v)
y = 6369784*np.sin(u)*np.sin(v)
z = 6369784*np.cos(v)
ax.plot_surface(x, y, z, color='blue',edgecolor="green")

u, v = np.mgrid[0:2*np.pi:20j, 0:np.pi:10j]
x = 1737400*np.cos(u)*np.sin(v) - 405500000
y = 1737400*np.sin(u)*np.sin(v)
z = 1737400*np.cos(v)
ax.plot_surface(x, y, z, color='grey',edgecolor="white")

xyzlim = np.array([ax.get_xlim3d(), ax.get_ylim3d(),ax.get_zlim3d()]).T
XYZlim = np.array([xyzlim[1] - xyzlim[0]])
maxes = 0.3*np.max(XYZlim)
ax.set_xlim3d(np.array([-maxes,maxes]) - 202750000)
ax.set_ylim3d(np.array([-maxes,maxes]))
ax.set_zlim3d(np.array([-maxes,maxes]))

ax.view_init(45,45)
ax.set_facecolor('black')
plt.axis("off")
plt.show()