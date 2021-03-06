in_ci <- function() {
  isTRUE(logical_env("CI"))
}

ci_type <- function() {
  if (in_travis()) {
    return("travis")
  }
  if (in_wercker()) {
    return("wercker")
  }
  ""
}

in_travis <- function() {
  return(nzchar(Sys.getenv("TRAVIS_REPO_SLUG")))
}

travis_build_info <- function() {
  slug <- Sys.getenv("TRAVIS_REPO_SLUG") %||% NULL

  if (is.null(slug)) {
    return(NULL)
  }

  slug_info <- strsplit(slug, "/")[[1]]

  list(
    user = slug_info[1],
    repo = slug_info[2],
    pull = Sys.getenv("TRAVIS_PULL_REQUEST") %||% NULL,
    branch = Sys.getenv("TRAVIS_BRANCH") %||% NULL,
    commit = Sys.getenv("TRAVIS_COMMIT") %||% NULL
  )
}

in_wercker <- function() {
  return(nzchar(Sys.getenv("WERCKER_GIT_BRANCH")))
}

ci_build_info <- function() {
  type <- ci_type()
  switch(type,
         travis = travis_build_info(),
         wercker = wercker_build_info()
         )
}

wercker_build_info <- function() {
  list(
       user = Sys.getenv("WERCKER_GIT_OWNER") %||% NULL,
       repo = Sys.getenv("WERCKER_GIT_REPOSITORY") %||% NULL,
       branch = Sys.getenv("WERCKER_GIT_BRANCH") %||% NULL,
       commit = Sys.getenv("WERCKER_GIT_COMMIT") %||% NULL
       )
}

github_comment <- function(text, info = NULL, token = settings$comment_token) {

  if (is.null(info)) {
    info <- ci_build_info()
  }

  if (!is.null(info$pull) && info$pull != "false") {
    response <- httr::POST("https://api.github.com",
      path = paste(sep = "/", "repos", info$user, info$repo, "issues", info$pull, "comments"),
      body = list("body" = jsonlite::unbox(text)),
      query = list(access_token = token),
      encode = "json")
  } else if (!is.null(info$commit)) {
    response <- httr::POST("https://api.github.com",
      path = paste(sep = "/", "repos", info$user, info$repo, "commits", info$commit, "comments"),
      body = list("body" = jsonlite::unbox(text)),
      query = list(access_token = token),
      encode = "json")
  }

  if (httr::status_code(response) >= 300) {
    message(httr::http_condition(response, "error", task = httr::content(response, as = "text")))
  }
}
