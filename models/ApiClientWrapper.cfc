/*
 * Copyright 2017 Joel Tobey <joeltobey@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * API Client Wrapper
 */
component
  extends="cfboom.lang.Object"
  displayname="Class ApiClientWrapper"
  output="false"
{
  property name="defaultNumberOfRetries" inject="coldbox:setting:defaultNumberOfRetries@cfboom-integration";
  property name="defaultRetrySleep" inject="coldbox:setting:defaultRetrySleep@cfboom-integration";
  property name="log" inject="logbox:logger:{this}";

  _instance['retryAdvisors'] = [];

  public cfboom.integration.models.ApiClientWrapper function init() {
    return this;
  }

  public void function onDIComplete() {
    _instance['numberOfRetries'] = javaCast("int", defaultNumberOfRetries);
    _instance['retrySleep'] = javaCast("int", defaultRetrySleep);
  }

  public void function setApiClient( required any apiClient ) {
    _instance['apiClient'] = apiClient;
  }

  public void function setNumberOfRetries( required numeric numberOfRetries ) {
    _instance['numberOfRetries'] = javaCast("int", numberOfRetries);
  }

  public void function setRetrySleep( required numeric retrySleep ) {
    _instance['retrySleep'] = javaCast("int", retrySleep);
  }

  public void function addRetryAdvisor( required cfboom.integration.RetryAdvisor retryAdvisor ) {
    arrayAppend(_instance.retryAdvisors, retryAdvisor);
  }

  public any function onMissingMethod( required string missingMethodName, required struct missingMethodArguments, numeric attempts = 0 ) {
    attempts++;

    // Call the API client
    if ( log.canDebug() ) {
      log.debug("Call to #_instance.apiClient.toString()#.#missingMethodName#() - #attempts# attempt(s)");
    }
    var res = _instance.apiClient[missingMethodName]( argumentCollection:missingMethodArguments );
    var prefix = res.getPrefix();

    // Deserialize JSON if needed
    prefix['deserializedContent'] = {};
    if (structKeyExists(prefix, "fileContent") && isJson(prefix.fileContent)) {
      prefix.deserializedContent = deserializeJson( prefix.fileContent );
    }

    // Do we need to retry?
    if ( attempts - 1 < _instance.numberOfRetries && canRetry( res ) ) {

      // Take a breather before we retry
      sleep(_instance.retrySleep);

      // Do the retry
      return onMissingMethod( argumentCollection:arguments );
    }

    return res;
  }

  private boolean function canRetry( required cfboom.http.HttpResponse res ) {
    // Return fast if status code is 2XX
    if (res.isSuccess())
      return false;

    // Loop through retry advisors to determine if we can retry
    for (var retryAdvisor in _instance.retryAdvisors) {
      if ( retryAdvisor.canRetry( res ) )
        return true;
    }

    // Return false if we get to this point
    return false;
  }

}
