% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/GraphUserInfoTwitter.R
\name{GraphUserInfoTwitter}
\alias{GraphUserInfoTwitter}
\title{Create twitter network graph with user information attributes}
\usage{
GraphUserInfoTwitter(df_collect, df_relations, df_users,
  lookup_missing_users = TRUE, twitter_token = NULL,
  writeToFile = FALSE)
}
\arguments{
\item{df_collect}{A dataframe containing the collected tweet data from \code{Collect}.}

\item{df_relations}{A dataframe containing the network relations data from \code{Create}.}

\item{df_users}{A dataframe containing the network users data from \code{Create}.}

\item{lookup_missing_users}{Logical. Request user information for any users missing from df_collect. Default 
is \code{TRUE}.}

\item{twitter_token}{An twitter authentication token from \code{Authenticate}.}

\item{writeToFile}{Logical. If \code{TRUE} a data frame of user information and the resulting network graph will 
be saved to file. Default is \code{FALSE}.}
}
\value{
A list containing a dataframe with user information and an igraph object of the twitter network with 
user node attributes.
}
\description{
Creates a network from the relations and users dataframes generated by Create. Network is supplemented with 
additional downloaded user information applied as node attributes.
}
\note{
Only supports twitter actor network at this time. Bimodal network support will require the filtering 
of twitter user ids from nodes of other types.
}
