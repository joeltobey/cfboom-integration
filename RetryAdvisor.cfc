/**
 * RetryAdvisor
 *
 * @author joeltobey
 * @date 6/13/17
 **/
interface {
  public boolean function canRetry( required cfboom.http.HttpResponse res );
}