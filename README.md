# CS3205 Team 2 K-Anonymity Design
## Architecture Design
![Architecture diagram](https://imgur.com/LEqzoeK.png)

- User connects to https://cs3205-2.comp.nus.edu.sg
- User is forwarded to cs3205-2 via port 80
- Nginx as web server forwards to Thin server via port 8080
- Thin as Ruby server
- Sinatra web application framework, language is Ruby
- SQLite database store local information if needed
- RESTful APIs used to communicate with server 4
- Communication link to s4 is protected with basic auth + client cert

### Application
![Application diagram](https://imgur.com/N6Jf7kJ.png)

- Sinatra application with Ruby
- Front end UI resides in views/
- CSS, images, Javascript for frontend ui manipulation resides in public/
- Functions and business logic defined in lib/kanon/web_app.rb
- Models defined in lib/kanon/models/
- Data pass through anonymizer module lib/kanon/anonymizer.rb before being returned
- Communication with server 4 defined by functions in lib/kanon/webapi.rb
- Global values stored in lib/kanon/konstants.rb
## Application Algorithm
### Quasi-identifiers
- Attributes of a dataset can be classified into 2 categories - quasi-identifiers and sensitive attributes.
- Quasi-identifiers are attributes that can be used to identify a person, such as race and age. The specific quasi-identifiers of our dataset are sex, zip code, date of birth, ethnicity and nationality.
- Sensitive attributes are characteristics of a person that may be of interest to a researcher, such as symptoms, blood type and medical history.
### Methodology
- K-anonymity works such that any set of quasi-identifiers must appear in at least k records in the anonymized dataset, whereby the value of k can be chosen. In this application, it is set to a default of 3. In order to achieve the above, the web application applies generalization and suppression techniques.
- Generalization is the replacement of individual values of attributes by a broader category. Specifically, zip code(postal code) can be generalized to a region (e.g. Queenstown) and date of birth to a age group (e.g. 30-39 years old). However, after the process of generalization, there may still remain records whose set of quasi-identifiers does not appear in at least k records.
- Suppression then takes place by omitting these records from the result returned to the researcher. Therefore, all records that are retrieved by the researcher will have a set of quasi-identifiers that appear in at least k records in the retrieved dataset.
## Security Claims
1. New registrations requires 2FA (OTP with Google Authenticator) to be configured, before the researcher can access search features with the new account.
    - A new registration is followed by a prompt to link the account to the user’s Google Authenticator mobile application, where OTP will be sent to every login. If the user close the OTP configuration and login in future, or enter any page URL in future, a check will be performed by the web application and the user will be prompted to configure OTP before a search can be performed using the new account. 

2. An attacker cannot force an user to execute unwanted state-changing actions on a web application in which they're currently authenticated.
    - With the implementation of CSRF tokens, an attacker cannot dupe a user into clicking/accessing an URL that perform an action as the permission of the legitimate logged in user. Form actions are accompanied with a CSRF token that changes with every load of the form, and is validated on the server side.
3. It is not possible for a single user to have 2 concurrent sessions at any time.
    - A single user is allowed to logged in to only one session at any time. If a user tries to log in using another browser or another system, the previous session associated with the same user will be terminated and he/she will required to re-login.

4. It is not possible for users to tamper with the session parameters.
     - An attacker cannot modify his session cookie to impersonate another user or to perform actions as another user. All session parameters are signed with a random secret every time the application first runs and cookies passed to the application is validated on the server side to ensure they are valid and not tampered with.

5. Form inputs are sanitized and validated
    - Login and registration form are validated for password length and empty field both front and backend. Input are sanitized too if there are any special characters used.

6. It is not possible to perform SQL injection attempts via form submissions. 
    - User inputs to the web application are sanitized server side before passing to server 4. Server 4 uses parameterized SQL queries to prevent code injection through malformed inputs.

7. It is not possible to retrieve search results without first obtaining permission(s) for searching various conditions.
    - Researchers that sign up are required to apply for permission to condition categories pertaining to their field of study. Application for a category must be approved by an admin researcher before the new researcher can gain access to view datasets pertaining to the category. Checks are also done before search to ensure that the conditions selected by the researcher are those that are granted to him/her. 

8. It is not possible for a normal researcher cannot execute the action of an admin researcher, namely, to view all request for permission, approve and decline request for permission.
    - Before performing an admin action, the access level of the researcher(e.g. normal or admin) is checked, and the admin action will only be followed through, if the researcher is found to be an admin.

9. It is not possible to perform sniffing and man-in-the-middle attacks on the connection between server 2 and 4
    - Attackers are unable to view the data passing between server 2 and 4 as the connection is protected with the use of TLS/SSL. 

10. It is not possible to directly invoke the Web API exposed by server 4 for server 2
    - The link between server 2 and server 4 is protected with the use of client certificate authentication and basic authentication. A valid client certificate must be presented alongside with the correct credentials in order to invoke server 4’s Web API.

11. Recaptcha is implemented on registration page to reduce registration spam. It’s based off Google Recaptcha V2 api.
    - Captcha prevents brute forcing of parameters by scripts and bots and encourage human testing. This reduces traffic on the server side and minimize server load.

## Application account information
An admin researcher account is provisioned for each testing group, please contact us for the details. For normal researcher account, please use the registration interface.