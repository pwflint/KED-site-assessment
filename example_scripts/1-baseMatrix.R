## Basic vector and flow field
N=20
dat <- expand.grid(x=seq(-1,1,l=20), y=seq(-1,1,l=20))
setDT(dat)

# Create base matrix by representing positions as complex numbers
dat[ , z := x+1i*y ]  
# create vector field by rotating z by 3pi/5.
dat[ , v := z*exp(1i*3*pi/5) ] 
dat[ , v := v/Mod(v) ]

dat[ , znew := z + .1*v  ]

plot(dat$z, pch=19)
arrows(Re(dat$z), Im(dat$z), Re(dat$znew), Im(dat$znew), length=0.05)

N=20
m=100

## Create individual streamlines within vector field
# each row is a streamline
pos <- matrix(nrow=N, ncol=m)

# make random starting positions
startz = runif(N,-1,1) + 1i*runif(N,-1,1) 

# put these starting positions into the first column of pos.
pos[,1] <- startz

# now create the subsequent columns by iterating the equations above.
for(i in 2:m){
  v <- pos[,i-1]*exp(1i*3*pi/5)
  pos[,i] <- pos[,i-1] + .02 * v/Mod(v)
}

plot(dat$z, pch=19,col="grey")
arrows(Re(dat$z), Im(dat$z), Re(dat$znew), Im(dat$znew), length=0.05,col="grey")

#apply the `lines` function over the rows of pos to add the streams
apply(pos, 1, lines)


