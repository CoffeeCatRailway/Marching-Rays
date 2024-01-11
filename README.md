# Marching-Rays
A side project spired from Sebastion Lague's 'Ray Marching & Marching Cubes' videos

**Small Disciption**
As it is now, it caps out around 40~ fps with the `cubesIn` size in `marching_rays.gdshader` being greater then 250. This is manily due to the shader looping over all "instances" in one frame.<br/>
I plan on trying to use compute shaders like in Sebastion's Ray Marching project so that smaller groups can be done in parallel

![preview](https://github.com/CoffeeCatRailway/Marching-Rays/raw/main/github%20resources/Godot_v4.1.3-stable_mono_win64_11-01-2024_24-31-10.png)
![preview](https://github.com/CoffeeCatRailway/Marching-Rays/raw/main/github%20resources/Godot_v4.1.3-stable_mono_win64_11-01-2024_36-31-10.png)

## Sources:
[![](https://img.youtube.com/vi/M3iI2l0ltbE/0.jpg)](https://www.youtube.com/watch?v=M3iI2l0ltbE)
[![](https://img.youtube.com/vi/Cp5WWtMoeKg/0.jpg)](https://www.youtube.com/watch?v=Cp5WWtMoeKg)
**Github Links:**
- https://github.com/SebLague/Marching-Cubes
- https://github.com/SebLague/Ray-Marching
- https://iquilezles.org/articles/distfunctions/
