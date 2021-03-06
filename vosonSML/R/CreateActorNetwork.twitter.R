# Create twitter actor network
# 
# Creates an actor network from collected tweets.
#
#' @param verbose Logical. Output additional information about the network creation. Default is \code{FALSE}.
#' 
#' @note For twitter data, actor networks can be created from multiple data frames (i.e. datasets collected individually
#' using \code{Collect} method. Simply create a list of the data frames that you wish to create a network from.
#' For example, \code{myList <- list(myTwitterData1, myTwitterData2, myTwitterData3)}
#' 
#' @return A twitter actor network as list containing a relations dataframe, users dataframe and igraph object.
#' 
#' @rdname CreateActorNetwork
#' @export
CreateActorNetwork.twitter <- function(x, writeToFile = FALSE, verbose = FALSE, ...) {

  from <- to <- edge_type <- timestamp <- status_id <- NULL
  is_retweet <- is_quote <- mentions_user_id <- reply_to_user_id <- NULL
  
  df <- x
  df <- data.table(df)
  
  df_stats <- networkStats(NULL, "collected tweets", nrow(df))
  
  cat("Generating twitter actor network...\n")
  flush.console()
  
  df_users <- data.frame("user_id" = character(0), "screen_name" = character(0))
  df_users <- rbind(df_users, subset(df, select = c("user_id", "screen_name"), stringsAsFactors = FALSE))
  
  # for speed we will pre-allocate dataCombined to a very large size (more rows than needed)
  # and after everything is finished we will delete the unused rows
  dataCombined <- data.table(
    from = as.character(c(rep("NA_f00", 20000000))),
    to = as.character(c(rep("NA_f00", 20000000))),
    edge_type = as.character(c(rep("NA_f00", 20000000))), #edgeType
    timestamp = as.character(c(rep("NA_f00", 20000000))), # timeStamp
    status_id = as.character(c(rep("NA_f00", 20000000))) # tweet_id
  )
  
  setkey(dataCombined, from) # set the key value of the data table
  
  nextEmptyRow <- 1 # so we can update rows in dataCombined in a relatively efficient way
  
  ## retweets
  # this creates a retweet edge between:
  # from (user retweeting) -- retweet --> to (user that tweeted)
  count <- 0
  for (i in 1:nrow(df)) {
    if ((df[i, is_retweet][[1]] == FALSE) || (is.na(df[i, is_retweet][[1]]))) { next }
    
    count <- count + 1
    
    dataCombined[nextEmptyRow, from := as.character(df$user_id[i][[1]])]
    dataCombined[nextEmptyRow, to := as.character(df$retweet_user_id[i][[1]])]
    dataCombined[nextEmptyRow, edge_type := as.character("retweet")]
    dataCombined[nextEmptyRow, timestamp := as.character(df$created_at[i][[1]])]
    dataCombined[nextEmptyRow, status_id := as.character(df$status_id[i][[1]])]
    
    df_users <- rbind(df_users, list(df$retweet_user_id[i][[1]], df$retweet_screen_name[i][[1]]))
    
    nextEmptyRow <- nextEmptyRow + 1
  }
  df_stats <- networkStats(df_stats, "retweets", count, TRUE)
  
  ## quotes
  # this creates a quote edge between:
  # from (user quoting) -- quote --> to (user being quoted)
  count <- 0
  for (i in 1:nrow(df)) {
    if ((df[i, is_quote][[1]] == FALSE) || (is.na(df[i, is_quote][[1]]))) { next }
    
    count <- count + 1
    
    dataCombined[nextEmptyRow, from := as.character(df$user_id[i][[1]])]
    dataCombined[nextEmptyRow, to := as.character(df$quoted_user_id[i][[1]])]
    dataCombined[nextEmptyRow, edge_type := as.character("quote")]
    dataCombined[nextEmptyRow, timestamp := as.character(df$created_at[i][[1]])]
    dataCombined[nextEmptyRow, status_id := as.character(df$status_id[i][[1]])]
    
    df_users <- rbind(df_users, list(df$quoted_user_id[i][[1]], df$quoted_screen_name[i][[1]]))
    
    nextEmptyRow <- nextEmptyRow + 1
  }
  df_stats <- networkStats(df_stats, "quoting others", count, TRUE)
  
  # dont create edges for mentions in retweets
  # if user retweets and types own text with mentions it becomes a quote tweet
  # and these are then counted
  if_retweet_inlude_mentions <- FALSE
  
  ## mentions
  # this creates a mention edge between:
  # from (user tweeting) -- mention / reply mention --> to (user mentioned)
  count <- 0
  mcount <- 0
  rmcount <- 0
  for (i in 1:nrow(df)) {
    if ((length(df[i, mentions_user_id][[1]]) < 1) |
        (length(df[i, mentions_user_id][[1]]) == 1 & is.na(df[i, mentions_user_id][[1]][[1]])) |
        (if_retweet_inlude_mentions == FALSE & df[i, is_retweet][[1]] == TRUE)) { 
      next 
    }
    
    count <- count + 1
    
    for (j in 1:length(df$mentions_user_id[i][[1]])) { # for each row of the likes data for post i
      
      etype <- "mention"
      if (!is.na(df[i, reply_to_user_id][[1]])) {
        # skip reply to actor as have this edge in replies
        if (df[i, reply_to_user_id][[1]] == df$mentions_user_id[i][[1]][j]) {
          next
        }
        etype <- "reply mention"
        rmcount <- rmcount + 1
      } else {
        mcount <- mcount + 1 
      }
      
      dataCombined[nextEmptyRow, from := as.character(df$user_id[i][[1]])]
      dataCombined[nextEmptyRow, to := as.character(df$mentions_user_id[i][[1]][j])]
      dataCombined[nextEmptyRow, edge_type := as.character(etype)]
      dataCombined[nextEmptyRow, timestamp := as.character(df$created_at[i][[1]])]
      dataCombined[nextEmptyRow, status_id := as.character(df$status_id[i][[1]])]
      
      df_users <- rbind(df_users, list(df$mentions_user_id[i][[1]][j], df$mentions_screen_name[i][[1]][j]))
      
      nextEmptyRow <- nextEmptyRow + 1
    }
  }
  df_stats <- networkStats(df_stats, "mentions", mcount, TRUE)
  df_stats <- networkStats(df_stats, "reply mentions", rmcount, TRUE)
  
  ## replies
  # this creates a reply edge between:
  # from (user replying) -- reply --> to (user being replied to)
  count <- 0
  for (i in 1:nrow(df)) {
    if (is.na(df[i, reply_to_user_id][[1]])) { next } # we check if there are retweets, if not skip to next row - reply_to
    
    count <- count + 1
    
    dataCombined[nextEmptyRow, from:= as.character(df$user_id[i][[1]])]
    dataCombined[nextEmptyRow, to := as.character(df$reply_to_user_id[i][[1]])]
    dataCombined[nextEmptyRow, edge_type := as.character("reply")]
    dataCombined[nextEmptyRow, timestamp := as.character(df$created_at[i][[1]])]
    dataCombined[nextEmptyRow, status_id := as.character(df$status_id[i][[1]])]
    
    df_users <- rbind(df_users, list(df$reply_to_user_id[i][[1]], df$reply_to_screen_name[i][[1]]))
    
    nextEmptyRow <- nextEmptyRow + 1 # increment the row to update in dataCombined
  }
  df_stats <- networkStats(df_stats, "replies", count, TRUE)
  
  dataCombined <- dataCombined[edge_type != "NA_f00"]
  
  # make a vector of all the unique actors in the network
  df_users <- unique(df_users)
  
  df_stats <- networkStats(df_stats, "nodes", nrow(df_users))
  df_stats <- networkStats(df_stats, "edges", sum(df_stats$count[df_stats$edge_count == TRUE]))
  
  # print stats
  if (verbose) { networkStats(df_stats, print = TRUE) }
  
  df_relations <- data.frame(
    from = dataCombined$from,
    to = dataCombined$to,
    edge_type = dataCombined$edge_type,
    timestamp = dataCombined$timestamp,
    status_id = dataCombined$status_id)
  
  g <- graph.data.frame(df_relations, directed = TRUE, vertices = df_users)
  
  V(g)$screen_name <- ifelse(is.na(V(g)$screen_name), paste0("ID:", V(g)$name), V(g)$screen_name)
  V(g)$label <- V(g)$screen_name
  
  if (writeToFile) { writeOutputFile(g, "graphml", "TwitterActorNetwork") }
  
  cat("Done.\n")
  flush.console()
  
  function_output <- list(
    "relations" = df_relations,
    "users" = df_users,
    "graph" = g
  )
  
  return(function_output)
}
