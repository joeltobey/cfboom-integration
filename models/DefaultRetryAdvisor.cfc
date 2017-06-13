/**
 * Class DefaultRetryAdvisor
 *
 * @author joeltobey
 * @date 6/13/17
 **/
component
  extends="cfboom.lang.Object"
  implements="cfboom.integration.RetryAdvisor"
  displayname="Class DefaultRetryAdvisor"
  output=false
{
  public cfboom.integration.models.DefaultRetryAdvisor function init() {
    return this;
  }

  public boolean function canRetry( required cfboom.http.HttpResponse res ) {
    // Sometimes the service is down, but will be up again on the next try
    if (!isNull(res.getErrorDetail()) && findNoCase("Unknown host", res.getErrorDetail())) {
      return true;
    }

    // Return false if we get to this point
    return false;
  }
}