################################################################
### Improving extinction projections across scales and habitats using the countryside species-area relationship 
### June 2017
### 
### Ines S. Martins (ines.martins@idiv.de)
################################################################

### Functions for scaling biodiversity response to habitat conversion across scales
### Code to draw Figure 2

### Set the simulation space
## N = dimension of the landscape 
## P = Proportion of native habitat remaining in the landscape (from 0 to 1, where 1 is all native habitat remaings)
## D = The dimension of the smallest square ( If 1 and N=1, 1x1 is the first dimension, if 0.1 and N=1, 0.1 x 0.1 is the first dimnsion,)
## h = Affinity for teh modified habitat
## zeta = z value of the SAR (rate at which species richness increase with area)
## n = number of simulations
## v = Clustering levels

library(raster)
library(landscapeR)
library(sp)


v<-c(1,2,5,10,41,82,410)

sim<-function(N,P,D,h,z,n){
  
  land <- function(N,P,D,af,zeta,nc){   ##nc -> number of clusters
    
    ### Create the lansdcape
    plots <- array(0, dim = c(N/D,N/D))   # create a empty matrix of 0
    res <- 0
    
    landR <- raster(plots)                #  working with landscapeR package
    cells<-makeClass(landR,nc,(((N/D)*(N/D)*P)/nc))
    landR[cells]=1
    plots<-as.matrix(landR)
    

    ### Define the functions SARs (Power function)
    
    #The classic SAR function
    SAR_pro<-function(A1,A0,z=zeta){
      species<-1-((A1/A0)^z)
      species
    }
    
    #The cSAR function
    cSAR_pro<-function(A1,A0,h1=h,z=zeta){
      species<-1-(((h1*(A0-A1)/A0)+(A1/A0))^z)
      species
    }
    
    #The linear function
    linear_pro<-function(A1,A0,h1=h,z=zeta){
      species<-1-((((h1)^z)*(A0-A1)/A0)+(A1/A0))  #Since for a modified habitat (1-sigma) = h^z
      species
    }
    
    
    
    ### Start the simulation 
    
    #set the starting point
    results <- NULL   
    size_real=D
    size=1
    while (size_real <= N) { 
      
      nplot = N/size_real  #number of plots
      SARs_all = matrix(0,nrow=(nplot*nplot),ncol=9)
      
      s<-1
      
      for (nx in 1: nplot){      ### gives nx lenght nplot
        for (ny in 1: nplot){    ### gives ny lenght nplot
          
          plot = matrix(1,size,size)
          for (x in 1:size){
            for (y in 1:size)
              
              plot[x,y] = plots[x + ((nx-1)*size), y + ((ny-1)*size)]
            
          }   # Runs for a particular sub-set of grids
          
          A1 <- sum(plot)
          A0 <- (sum(plot) + (sum(plot==0)*D))
          
          SARs_all[s,1] <-size
          SARs_all[s,2] <- SAR_pro(A1,A0)
          SARs_all[s,3] <- cSAR_pro(A1,A0)
          SARs_all[s,4] <- linear_pro(A1,A0)
          SARs_all[s,5] <- A1
          SARs_all[s,6] <- A0
          
          s<- s+1
          
        }
      }
      
      results <- rbind(results,SARs_all)
      
      size_real = size_real * 2
      size = size * 2                          
      
    }
    
    ###Store the results
    SAR_pro_mean <- tapply (results[,2],results[,1],mean)   #Creates a vector with the means
    cSAR_pro_mean <- tapply (results[,3],results[,1],mean)
    linear_pro_mean <- tapply (results[,4],results[,1],mean) 
    size_A1_mean <- tapply (results[,5],results[,1],mean) 
    size_A0_mean <- tapply (results[,6],results[,1],mean)
    SAR_pro_sd <- tapply (results[,2],results[,1],sd)   #Creates a vector with the sd
    cSAR_pro_sd <- tapply (results[,3],results[,1],sd)
    linear_pro_sd <- tapply (results[,4],results[,1],sd)
    
    SAR_pro_mean_mat = matrix(SAR_pro_mean,length(SAR_pro_mean),1)  # Creates a matrix with the means
    cSAR_pro_mean_mat = matrix(cSAR_pro_mean,length(cSAR_pro_mean),1)
    linear_pro_mean_mat = matrix(linear_pro_mean,length(linear_pro_mean),1)
    size_mean_A1_mat = matrix(size_A1_mean,length(size_A1_mean),1)
    size_mean_A0_mat = matrix(size_A0_mean,length(size_A0_mean),1)
    SAR_pro_sd_mat = matrix(SAR_pro_sd,length(SAR_pro_sd),1)  # Creates a matrix with the sd
    cSAR_pro_sd_mat = matrix(cSAR_pro_sd,length(cSAR_pro_sd),1)
    linear_pro_sd_mat = matrix(linear_pro_sd,length(linear_pro_sd),1)
    
    SARs <- data.frame(cbind(unique(results[,1]), SAR_pro_mean_mat, cSAR_pro_mean_mat,linear_pro_mean_mat, size_mean_A1_mat,size_mean_A0_mat,SAR_pro_sd_mat, cSAR_pro_sd_mat,linear_pro_sd_mat))
    colnames(SARs) <- c("grain","SAR_pro","cSAR_pro","linear_pro","A1","A0","SAR_pro_sd","cSAR_pro_sd","linear_pro_sd")
    
    return(SARs)
  }
  
  run<-function(N,P,D,h,z,n){
    
    dat <- c()
    for (i in 1:n)
    {
      nc<-sample(v,1)
      model <- land(N,P,D,h,z,nc)
      nextcol <-  data.frame(model)
      dat <- rbind(dat, nextcol)
      print(nc)
    }
    dat
    return(dat)
  }
  
  SARs <- run(N,P,D,h,z,n)  #nc Cluster
  
  SARs <- aggregate(. ~ grain , data=SARs,mean,na.action = na.pass)  # Do not run if we want both sd and mean
  
  ###PLOT
  # Proportion of species remaining after 90% habitat loss - Figure 2
  
  par(mar=c(5,5,1,1)) 
  
  plot (log(SARs[,6]), (SARs[,2]), axes = FALSE, type = "o", cex=0.5,lwd = 1.5,ylim=c(0,1.2), 
        xlab= "Area of the sampling window \n (Log Scale)", ylab= "Fraction of species remaining\n (average across sampling windows)")  #SAR
  axis(1, at=(log(SARs[,6])),SARs[,6])
  axis(2,seq(0,1.2,0.2))
  box(which = "plot")
  lines(log(SARs[,6]),(SARs[,3]), col="red",lty=2,pch=22, type = "o",lwd = 1.5,cex=0.5) #cSAR
  lines(log(SARs[,6]),(SARs[,4]), col="blue", lty=3,pch=23,type = "o",lwd = 1.5,cex=0.5)  #Linear
  
  legend(5,1.2, c("SAR","cSAR","linear"),lty=c(1,2,3), lwd=c(1.3,1.3,1.3),col=c("black","red","blue"),pch=c(21,22,23), bty="n",pt.bg = 'white')
  
  #Add the standart deviation bars
  arrows(log(SARs[,6]),(SARs[,2])-(SARs[,7]),log(SARs[,6]),(SARs[,2])+(SARs[,7]), code=3,lty=1,length=0.02, angle = 90,col = "black")
  arrows(log(SARs[,6]),(SARs[,3])-(SARs[,8]),log(SARs[,6]),(SARs[,3])+(SARs[,8]), code=3,lty=1, length=0.02, angle = 90,col = "red")
  arrows(log(SARs[,6]),(SARs[,4])-(SARs[,9]),log(SARs[,6]),(SARs[,4])+(SARs[,9]), code=3,lty=1, length=0.02, angle = 90,col = "blue")
  
}


### Run n=1000 simulations 
###For N=64, P=0.1, D=1, h=0.01 and z=0.2 -> Figure 2 

sim(64,0.1,1,0.01,0.2,1000)


