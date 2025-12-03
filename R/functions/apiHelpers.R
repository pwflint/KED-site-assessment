# API Helper Functions
# Functions for REST API access with caching and error handling

#' Check if cached data exists and is valid
#'
#' @param cache_path Path to cache file
#' @param max_age Maximum age of cache in days (default: 30)
#' @return Logical: TRUE if cache is valid, FALSE otherwise
check_cache <- function(cache_path, max_age = 30) {
  if (!file.exists(cache_path)) {
    return(FALSE)
  }
  
  file_age <- as.numeric(Sys.Date() - as.Date(file.info(cache_path)$mtime))
  
  if (file_age > max_age) {
    return(FALSE)
  }
  
  return(TRUE)
}

#' Make API request with retry logic
#'
#' @param url API endpoint URL
#' @param params List of query parameters
#' @param max_retries Maximum number of retry attempts (default: 3)
#' @param timeout Request timeout in seconds (default: 30)
#' @return Response object or NULL on failure
api_request <- function(url, params = NULL, max_retries = 3, timeout = 30) {
  for (attempt in 1:max_retries) {
    tryCatch({
      response <- httr::GET(
        url,
        query = params,
        httr::timeout(timeout)
      )
      
      if (httr::status_code(response) == 200) {
        return(response)
      } else if (httr::status_code(response) == 429) {
        # Rate limited - wait and retry
        Sys.sleep(2^attempt)  # Exponential backoff
        next
      } else {
        warning(paste("API request failed with status:", httr::status_code(response)))
        return(NULL)
      }
    }, error = function(e) {
      if (attempt == max_retries) {
        warning(paste("API request failed after", max_retries, "attempts:", e$message))
        return(NULL)
      }
      Sys.sleep(2^attempt)  # Exponential backoff
    })
  }
  
  return(NULL)
}

#' Download and cache data from API
#'
#' @param url API endpoint URL
#' @param params List of query parameters
#' @param cache_path Path to cache file
#' @param max_age Maximum age of cache in days
#' @param parse_fun Function to parse response (default: jsonlite::fromJSON)
#' @return Parsed data or NULL on failure
fetch_with_cache <- function(url, params = NULL, cache_path, max_age = 30, 
                             parse_fun = jsonlite::fromJSON) {
  
  # Check cache first
  if (check_cache(cache_path, max_age)) {
    message(paste("Loading from cache:", cache_path))
    return(readRDS(cache_path))
  }
  
  # Make API request
  message(paste("Fetching from API:", url))
  response <- api_request(url, params)
  
  if (is.null(response)) {
    warning("API request failed, returning NULL")
    return(NULL)
  }
  
  # Parse response
  tryCatch({
    content <- httr::content(response, as = "text", encoding = "UTF-8")
    data <- parse_fun(content)
    
    # Cache the result
    dir.create(dirname(cache_path), showWarnings = FALSE, recursive = TRUE)
    saveRDS(data, cache_path)
    message(paste("Data cached to:", cache_path))
    
    return(data)
  }, error = function(e) {
    warning(paste("Error parsing API response:", e$message))
    return(NULL)
  })
}

#' Validate API response data
#'
#' @param data Data to validate
#' @param required_fields Vector of required field names
#' @return Logical: TRUE if valid, FALSE otherwise
validate_api_data <- function(data, required_fields = NULL) {
  if (is.null(data)) {
    return(FALSE)
  }
  
  if (!is.null(required_fields)) {
    if (is.data.frame(data)) {
      missing_fields <- setdiff(required_fields, names(data))
    } else if (is.list(data)) {
      missing_fields <- setdiff(required_fields, names(data))
    } else {
      return(FALSE)
    }
    
    if (length(missing_fields) > 0) {
      warning(paste("Missing required fields:", paste(missing_fields, collapse = ", ")))
      return(FALSE)
    }
  }
  
  return(TRUE)
}

