```{r}
# libraries
library(readr)
library(ggplot2)
library(cowplot)
library(randomForest)
library(dplyr)
library(corrplot)
library(fastDummies)
library(glmnet)
library(lm.beta)
library(tidyverse)
library(cluster)
library(knitr)
library(factoextra)
library(car)
library(gt)
library(gtsummary)
```

```{r}
# Data cleaned 
Data_STAT4893W <- read_csv("C:\\Users\\54088\\OneDrive\\桌面\\SW\\S5 2023\\STAT 4893W\\Data_STAT4893W.csv")

original_data <- Data_STAT4893W

# Remove several rows
rows_to_delete <- c( 13, 14, 33, 34, 35, 37, 38, 46, 73, 75, 76)

cleaned_data <- original_data[-rows_to_delete, ]

cleaned_data[cleaned_data == 'NA'] <- 0

# convert data into numeric
cleaned_data[] <- lapply(cleaned_data, as.numeric)



# Remove V8 and V80 columns(text, )
cleaned_data <- cleaned_data[,-8]
cleaned_data <- cleaned_data[,-80]
cleaned_data <- cleaned_data[,-129]
cleaned_data <- cleaned_data[,-155]
```

```{r}
# demographic
demographic_data <- cleaned_data

# Age_Groups
group1 <- sum(demographic_data$AgeGroup_1)
group2 <- sum(demographic_data$AgeGroup_2)
group3 <- sum(demographic_data$AgeGroup_3)
group4 <- sum(demographic_data$AgeGroup_4)


age_group <- data.frame(
  group_name = c("Youth", "Young adult", "Adults", "Older adults"),
  counts = c(group1, group2, group3, group4) 
)

kable(age_group)


# Latin_groups
latin0 <- sum(cleaned_data$V9)
latin888 <- sum(cleaned_data$V10)
latin1 <- sum(cleaned_data$V11)
latin2 <- sum(cleaned_data$V12)
latin10 <- sum(cleaned_data$V20)
latin11 <- sum(cleaned_data$V21)
latin15 <- sum(cleaned_data$V25)
latin18 <- sum(cleaned_data$V28)
latin19 <- sum(cleaned_data$V29)
latin26 <- sum(cleaned_data$V36)
latin28 <- sum(cleaned_data$V38)
latin32 <- sum(cleaned_data$V42)
latin999 <- sum(cleaned_data$V52)

latin_group <- data.frame(
      latin_name = c("Not of Hispanic, Latino/a, or Spanish origin",
                                        "Latin American",
                                        "Audalusian",
                                        "Catalonian",
                                        "Central American",
                                        "Colombian",
                                        "Cuban",
                                        "Dominican",
                                        "Spaniard",
                                        "Nicaraguan",
                                        "Puerto Rican",
                                        "Unknown", 
                                        "Decline to answer"), 
        counts = c(latin0, latin1, latin2, latin10, latin11, latin15, latin18, latin19, latin26, latin28, latin32, latin888, latin999)
)

kable(latin_group)


# Race_groups
race2 <- sum(cleaned_data$V54)
race3 <- sum(cleaned_data$V55)
race6 <- sum(cleaned_data$V58)
race13 <- sum(cleaned_data$V65)
race22 <- sum(cleaned_data$V74)
race23 <- sum(cleaned_data$V75)
race24 <- sum(cleaned_data$V76)

race_group <- data.frame(
    race_name = c("Black or African descent", "White or European descent", "Chinese", "Other South Asian", "Other race", "Hispanic, Latina, Spanish origin", "White, Hispanic origin"), 
    counts = c(race2, race3, race6, race13, race22, race23, race24)
)

kable(race_group)


age <- data.frame(
    names = c("n", "mean", "sd"), 
    value = c(length(cleaned_data$V6), mean(cleaned_data$V6), sd(cleaned_data$V6))
)
kable(age)


barplot(table(demographic_data$Age), main = "Age distribution", xlab = "Age", ylab = "Count")

trial2 <- demographic_data %>% select( Gender, Immigrant, Refugee, Community, School, Income, Country, State )
trial2 %>% tbl_summary()
```

```{r}
# Multiple Regression for secondary trauma
SE5_model <- 5*cleaned_data$CFS_SecondaryTrauma

SE_model <- lm(SE5_model ~  COPE_Positive + 
                                      COPE_MentalDis + 
                                      COPE_Venting +
                                      COPE_InstrumentalSup +
                                      COPE_Active +
                                      COPE_Denial + 
                                      COPE_Religious + 
                                      COPE_Humor +
                                      COPE_BehavioralDis + 
                                      COPE_Restraint + 
                                      COPE_EmotionalSup + 
                                      COPE_Substance + 
                                      COPE_Acceptance +  
                                      COPE_Suppression + 
                                      COPE_Planning
                                    , data = cleaned_data)
SE_model
summary(SE_model)
# compared with SE in beta
beta_SE <- lm.beta(SE_model)$coef

# Standardize variables to get standardized coefficients
mtcars.std <- lapply(mtcars, scale)
# Gather summary statistics
stats.table <- as.data.frame(summary(SE_model)$coefficients)
# Add a row to join the variables names and CI to the stats
stats.table <- cbind(row.names(stats.table), stats.table, beta_SE)
# Rename the columns appropriately
names(stats.table) <- cbind("Term", "Estimate", "SE", "t", "p-value", "beta.coef")
#nice_table(stats.table)


rank <- data.frame(
  rank_name = c("Religious", "MentalDisengagement", "Substance", "EmotionalSupport", "Positive", "Active", "Denial", "Suppression", "BehavioralDisengagement", "Humor", "Planning", "Acceptance", "Venting", "Restaint", "InstrumentalSupport"),
  ranked = c(2.39, 2.11, 1.64, 1.56, 1.41, 0.78, 0.58, 0.20, 0.07, -0.06, -0.82, -0.84, -1.03, -1.2, -1.87)
)
rank$rank_name <- factor(rank$rank_name, levels = rank$rank_name[order(rank$ranked)])


ggplot(rank, aes(x = rank_name, y = ranked)) +
  geom_bar(stat = "identity", fill = "coral") +
  coord_flip() +  # This makes the bars horizontal
  labs(title = "The rank of Secondary Trauma ",
       x = "",
       y = "") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 24, hjust = 0.5),
    axis.text = element_text(size = 12)
  )


par(mfrow = c(1, 3))
qqnorm(residuals(SE_model))
qqline(residuals(SE_model))

plot(SE_model)

vif(SE_model)
```

```{r}
#Multiple Regression for Job Burnout
CFS_JB <- 8*cleaned_data$CFS_JobBurnout
JB_model <- lm(CFS_JB ~  COPE_Positive + 
                                      COPE_MentalDis + 
                                      COPE_Venting +
                                      COPE_InstrumentalSup +
                                      COPE_Active +
                                      COPE_Denial + 
                                      COPE_Religious + 
                                      COPE_Humor +
                                      COPE_BehavioralDis + 
                                      COPE_Restraint + 
                                      COPE_EmotionalSup + 
                                      COPE_Substance + 
                                      COPE_Acceptance +  
                                      COPE_Suppression + 
                                      COPE_Planning
                                    , data = cleaned_data)
summary(JB_model)

# compared with JB in beta
beta_JB <- lm.beta(JB_model)$coef

# Gather summary statistics
stats.table <- as.data.frame(summary(JB_model)$coefficients)
stats.table
# Add a row to join the variables names and CI to the stats
stats.table <- cbind(row.names(stats.table), stats.table, beta_JB)
stats.table
# Rename the columns appropriately
names(stats.table) <- cbind("Term", "Estimate", "SE", "t", "p-value", "beta.coef")
stats.table
# nice_table(stats.table)
rank(stats.table$t)


rank <- data.frame(
  rank_name = c("Religious", "MentalDisengagement", "Substance", "EmotionalSupport", "Positive", "Active", "Denial", "Suppression", "BehavioralDisengagement", "Humor", "Planning", "Acceptance", "Venting", "Restaint", "InstrumentalSupport"),
  ranked = c(-0.74, 2.41, 2.95, 0.04, -0.64, -1.83, 0.02, -0.71, 1.05, -0.49, 1.20, 0.83, 1, -0.6, 0.1)
)
rank$rank_name <- factor(rank$rank_name, levels = rank$rank_name[order(rank$ranked)])


ggplot(rank, aes(x = rank_name, y = ranked)) +
  geom_bar(stat = "identity", fill = "coral") +
  coord_flip() +  # This makes the bars horizontal
  labs(title = "The rank of Job Burnout",
       x = "",
       y = "") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 24, hjust = 0.5),
    axis.text = element_text(size = 12)
  )
```

```{r}
# Objective 2 
coping_data <- cleaned_data[, -(1:160)]
coping_data <- coping_data[, -(16:17)]

# PCA
pca.out <- prcomp(coping_data, scale = TRUE)
pca.out
summary(pca.out)
plot(pca.out, type = "l", main = "Variance")

# we will choose 8 components

pca.var <- pca.out$sdev^2
pca.var.per <- round(pca.var/sum(pca.var)*100, 1)
barplot(pca.var.per, main = "Scree Plot", xlab = "PC", ylab = "Percent Variation")


# K-mean clustering

# Entities (e.g., States)
entities <- c("COPE_Positive", "COPE_MentalDisengagement", 
                                        "COPE_Venting" ,
                                        "COPE_InstrumentalSupport" ,
                                        "COPE_Active",
                                        "COPE_Denial",
                                        "COPE_Religious",
                                        "COPE_Humor",
                                        "COPE_BehavioralDisengagement",
                                        "COPE_Restaint",
                                        "COPE_EmotionalSupport",
                                        "COPE_Substance",
                                        "COPE_Acceptance" ,
                                        "COPE_Suppression",
                                        "COPE_Planning")


positive <- mean(cleaned_data$COPE_Positive)
mentaldis <- mean(cleaned_data$COPE_MentalDisengagement)
venting <- mean(cleaned_data$COPE_Venting)
instumentalsupport <- mean(cleaned_data$COPE_InstrumentalSupport)
active <- mean(cleaned_data$COPE_Active)
denial <- mean(cleaned_data$COPE_Denial)
religious <- mean(cleaned_data$COPE_Religious)
humor <- mean(cleaned_data$COPE_Humor)
behavioraldis <- mean(cleaned_data$COPE_BehavioralDisengagement)
restaint <- mean(cleaned_data$COPE_Restaint)
emotionalsup <- mean(cleaned_data$COPE_EmotionalSupport)
substance <- mean(cleaned_data$COPE_Substance)
acceptance <- mean(cleaned_data$COPE_Acceptance)
suppression <- mean(cleaned_data$COPE_Suppression)
planning <- mean(cleaned_data$COPE_Planning)


# Features
Feature1 <- c(positive, mentaldis, venting, instumentalsupport, active, denial, religious, humor, behavioraldis, restaint, emotionalsup, substance, acceptance, suppression, planning )

Feature1 <- scale(Feature1)
Feature1
# Combine the data
my_dataset <- data.frame(Entity = entities,
                         mean = Feature1)

# Standardize the Data
my_dataset$mean_scaled <- scale(my_dataset$mean)

# Apply k-means clustering
set.seed(123)  # Setting seed for reproducibility
k3 <- kmeans(my_dataset$mean_scaled, centers=3)

# Add cluster assignment to your data
my_dataset$cluster <- as.factor(k3$cluster)

# Visualize the results
ggplot(my_dataset, aes(x=Entity, y=mean_scaled, color=cluster)) +
  geom_point(size=4) +
  theme(axis.text.x = element_text(angle=45, hjust=1)) +
  labs(title="K-means Clustering of Coping Strategies", y="Standardized Mean", x="Coping Strategies")
```
