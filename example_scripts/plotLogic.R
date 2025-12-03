## Script for following the logic of a flow field plot, outlining parameters and 
## variables. 

# A plot uses a rational function defined by the matrix (z) and a complex number (i)
## Example function:
flowFunction <- \(z) (z-.5)*(z+.5)*z / ((z-0.5i+0.5)* (z+0.5i-0.5)*(z+.1-.1i))

## The vector field can be created by a function.
## The starting positions (z) and vectors (v) are defined by a complex number 1i.
plotFlow <- function(FUN,col="black") {
  
  dat <- expand.grid(x=seq(-1,1,l=20), y=seq(-1,1,l=20))
  setDT(dat)
  
  dat[ , z := x+1i*y ]  # represent position as a complex number
  dat[ , v := FUN(z) ]  # create vector field
  dat[ , v := v/Mod(v) ]
  dat[ , znew := z + .1*v  ]
  plot(dat$z, pch=19,col=col)
  arrows(Re(dat$z), Im(dat$z), Re(dat$znew), Im(dat$znew), length=0.05,col=col)
}

## Create N streamlines and m iterations over the vector field, 
## defined by data object `pos` and value `startz`

makeStreams <- function(startpos,m=200,FUN,d=0.02){
  pos <- matrix(nrow=N, ncol=m)
  startz = runif(N,-1,1) + 1i*runif(N,-1,1)
  pos[,1] <- startz
  for(i in 2:m){
    v <- FUN(pos[,i-1])
    pos[,i] <- pos[,i-1] + d * v/Mod(v)
  }
  pos
}

N=100 # N represents streamlines
startZ <- runif(N, -1,1) + 1i*runif(N, -1,1)

pos <- makeStreams(startZ, FUN = flowFunction)

plotFlow(flowFunction, col="grey")
apply(pos, 1, lines)

## Same plot above with more paths and less iteration
N=1000
startZ <- runif(N, -1,1) + 1i*runif(N,-1,1)
pos <- makeStreams(startZ,FUN=flowFunction, d=0.01) # d limits no. of iterations
plot(NA, xlim=c(-1,1), ylim=c(-1,1))
apply(pos, 1, lines)

## Same plot with scattered linetypes
pos <- cbind(Re(as.vector(pos)), Im(as.vector(pos)))
scattermoreplot(pos,size=c(800,600), xlim=c(-1,1), ylim=c(-1,1))

## Illustrating sinks and sources of flow
scattermoreplot(pos,size=c(800,600), xlim=c(-1,1), ylim=c(-1,1))
points(c(-0.5+0.5i, 0.5-0.5i,-0.1+0.1i), col="blue", cex=2,pch=4, lwd=4) # denominator roots. Ridges and troughs. Saddle points.
points(c(-0.5+0i, 0.5,0), col="red", cex=2,pch=1, lwd=4) # numerator roots. Source & sink
