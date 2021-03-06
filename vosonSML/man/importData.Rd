% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ImportData.R
\name{ImportData}
\alias{ImportData}
\title{Import vosonSML data previously saved to disk using the `Collect()` function.}
\usage{
ImportData(file, dataSource)
}
\arguments{
\item{file}{character, specifying the file path to the data to be imported}

\item{dataSource}{character, the type of social media. Currently supports
"facebook", "twitter", "youtube", and "instagram" (not case sensitive).}
}
\value{
A dataframe with specific class attributes for vosonSML functionality
}
\description{
This function imports social media data previously collected and saved
to disk using the `Collect()` function in vosonSML. Using this
function to import data ensures that the correct classes are applied
to the dataframe, in order for vosonSML to know how to handle it
(e.g. creating different types of networks using the `Create` function).
}
\examples{

\dontrun{
require(magrittr)
## Facebook example

# Specify your API keys
appID <- "xxxx"
appSecret <- "xxxx"

# Authenticate and Collect some data (and save data to disk using `writeToFile=TRUE`)
myFacebookData <- Authenticate("Facebook", appID = appID, appSecret = appSecret) \%>\%
   Collect(pageName="StarWars", rangeFrom="2015-03-01",
     rangeTo="2015-03-02", writeToFile=TRUE)

# Import the data (that was saved to disk in the previous step)
myStarWarsData <- ImportData("2015-03-01_to_2015-03-02_StarWars_FacebookData.csv","facebook")

# Create a network using the imported dataframe object
myNetwork <- myStarWarsData \%>\% Create("Bimodal")
}
}
\seealso{
\code{\link{Collect}}
}
\author{
Timothy Graham <timothy.graham@anu.edu.au>
}
