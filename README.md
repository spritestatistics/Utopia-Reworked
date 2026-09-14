# Utopia Reworked
Modded version of cary's food chain simulator, which he demonstrated in his YouTube video! https://www.youtube.com/watch?v=Zy9N48udcdc

Note: Processing 4 was used to make this simulator. Download Processing 4 here in order to run! https://processing.org/download

Controls: Press WASD + Space to move around. Press 'C' to have the camera start following the highlighted creature! (The one blinking white that is nearest to you.) Press 'V' to change whether to control creatures or not, default turned off

Mutations have a 5% chance of appearing. Higher fertile lands = Faster plant growth, however lower fertile lands = slow plant growth. You can also play as the creatures, give it a try! (Except for the plants, but there's no reason to anyway) I also split the predator creature into 3 different species that eats one type of all cows. Cows and the predators can eat secondary or trinary foods that are not as appeasing to them, When eating secondary foods, creatures will only gain 75% of the calories, while eating trinary foods give only 50%, but they will prioritize primary foods first. (Omnivores? Prehaps!) (Apex predator? Prehaps!) Let me know what I should add!

There also a third family now! I call it the "middle-grounds", where members of this family share traits from both the mountain family and the low-land family.

I also implemented Genetic Shift! Heres how it works:
There are 5 stats, Speed, Stamina, Metabolism, Vision, and Fertility. Each creature will have these stats ranging from 0-1. When the simulation first starts, the creatures that are generated will have their stats randomly generated between 0.4 and 0.6 for each stat. When a new creature is born, they will mutate +/- 0 to 0.075 stat points for each stat, the stats chosen to mutate from is the mean of the stats of the 2 parents. I only added 5 stats for simplicity, but they do serve some major purposes:

**Speed**
A higher speed stat corresponds to more speed. You can get up to +15% more speed at max 1 or -15% less speed at the minimum 0, which can make finding faraway food, running/catching predators/prey easier! However, running faster leads to burning energy faster, so a creature burns energy 30% faster when running when this stat is max, and 30% slower when this stat is at 0.

**Stamina**
Similar to Speed but is a bit different. Higher stamina corresponds to lower speed output, but energy burn is up to 20% slower, and vice versa for lower stamina. A creature with high speed and low stamina can run very fast, however burn energy over 50% faster.

**Metabolism**
Metabolism is pretty complicated so ill just summarize it. Higher metabolism increases hunger and thrist growth rate (up to +20%), even when the creature isnt moving, (Note that when hunger or thrist growth is increased, the creature gains urgency to do that task quicker) aswell as the creatures speed (Speed goes up by up to 15%), since higher metabolism = faster processing, However, aging is quicker, so lifespan is up to -20% less. Its vice versa for lower metabolism.

**Vision**
This one is more simple. Increases or decreases the creature's vision by up/down 3 tiles. It may seem like a good idea to get vision, but more vision requires more energy, so it isnt that good when populations are high.

**Fertility (or Freakyness if your Cary)**
Increases or decreases freakiness urgency by up/down 20%. however the higher fertility the more hunger you consume even when you arent moving. (up to 15% and vice versa)

There could definitely be improvements to this system, I was also thinking about randomizing the stats between 0 and 1 among primordial species instead of 0.4 and 0.6, but I decided not to. You can change it if you want though (in Trait.pde).

Also, I used AI for a lot of the things I added, but just know that I have full control over what gets added.
I do have some programming experience myself too.

# Update Log
**(1.1.a)**
Fixed some bugs and made the default stats more coherent with genetic shift (predators can now keep up with the cows innovations, fertility now has an actual downside, stamina hunger growth factor now works properly. (before, creatures would just go as high stamina as possible to conserve energy as stamina didn't actually impact the speed, the speed stat impacted the stamina speed bonus))
**The Biodiversity Update (1.1)**
-Added genetic shift/natural selection
-Added a third family of species
