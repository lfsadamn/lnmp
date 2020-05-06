Function _getHttpCode($url){
  if(!$url){
    return "404"
  }

  $header=curl -sI $url

  if(!$header){
    return "404"
  }

  return $header.split(" ")[1].toString()
}
