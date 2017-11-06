### CS3205 Team 2
# Kanon : Medical Research Query Portal

## Project Introduction
Our team’s subsystem provides a web interface and control functions for researchers to use to query for medical data. Our Medical Query Research Portal allows for displaying of information from the database, as long as that information cannot be used to identify individuals.  This is achieved by enforcing the k-anonymity property of the result sets through data anonymization algorithms.

## K-Anonymity Algorithm Concept

### Quasi-Identifiers

Attributes of a dataset can be classified into 2 categories: quasi-identifiers and sensitive attributes.
- Quasi-identifiers are attributes that can be used to identify a person, such as race and age. The specific quasi-identifiers of our dataset are sex, zip code, date of birth, ethnicity and nationality. 
- Sensitive attributes are characteristics of a person that may be of interest to a researcher, such as symptoms, blood type, medical readings and history.

### Methodology

K-anonymity works such that any set of quasi-identifiers must appear in at least k records in the anonymized dataset, whereby the value of k can be chosen. In this application, it is set to a default factor of 3. In order to achieve the above, the web application applies data generalization and suppression techniques.

Generalization is the replacement of individual values of attributes by a broader category. Specifically, zip code (postal code) can be generalized to a region (e.g. Queenstown) and date of birth to a age group (e.g. 30-39 years old). However, after the process of generalization, there may still remain records whose set of quasi-identifiers does not appear in at least k records.

Suppression then takes place by omitting these records from the result returned to the researcher. Therefore, all records that are retrieved by the researcher will have a set of quasi-identifiers that appear in at least k records in the retrieved dataset.


## Architecture Design

![Architecture diagram](https://imgur.com/LEqzoeK.png)

- The application will be hosted at https://cs3205-2.comp.nus.edu.sg
- Upon connection, user is forwarded to cs3205-2 via [port 80]
- The nginx web server then forwards to the Thin server via [port 8080]
    - We will be running Thin as our application server
    - The implementation programming language is Ruby, which runs a Sinatra web application framework
- A local SQLite database stores application specific information if needed
- Communication to the overall system database (at Server 4) will be performed via RESTful API
    - Communication link to Server 4 is protected with Basic Auth and our own client cert

# Web Application Design
![Application diagram](https://imgur.com/N6Jf7kJ.png)

Our system is a Sinatra application with Ruby:
- Front end UI resides in views/
- CSS, images, Javascript for frontend UI manipulation resides in public/
- Functions and business logic defined in lib/kanon/web_app.rb
- Models defined in lib/kanon/models/
- Queried result-sets pass through anonymizer module lib/kanon/anonymizer.rb before being returned to the researcher
- Communication with Server 4 defined by functions in lib/kanon/webapi.rb
- Global values stored in lib/kanon/konstants.rb

# Application Testing

An admin researcher account is provisioned for each testing group, please contact us for the details. For normal researcher account, please use the registration interface. You will also need a mobile device with Google Authenticator installed.

# Security Claims

## Server and Infrastructure Security

S1-SSL : 		It is not possible to perform sniffing and man-in-the-middle attacks on the connection between server 2 and 4

- Attackers are unable to view the data passing between server 2 and 4 as the connection is protected with the use of TLS/SSL.

S2-WEBAPI :	It is not possible to directly invoke the Web API exposed by Server 4 for Server 2

- The link between server 2 and server 4 is protected with the use of client certificate authentication and basic authentication. A valid client certificate must be presented alongside with the correct credentials in order to invoke server 4’s Web API.

## Web Application Security

W1-CSRF :		An attacker cannot force an user to execute unwanted state-changing actions on a web application in which they're currently authenticated.
- With the implementation of CSRF tokens, an attacker cannot dupe a user into clicking/accessing an URL that perform an action as the permission of the legitimate logged-in user. Form actions are accompanied with a CSRF token that changes with every load of the form, and is validated on the server side.

W2-SESSION :	It is not possible for a single user to have 2 concurrent sessions at any time.

- A single user is only allowed to log into one session at any time. If a user tries to log in using another browser or another system, the previous session associated with the same user will be terminated and he/she will be required to re-login.

W3-COOKIES :	It is not possible for users to tamper with the session parameters.

- An attacker cannot modify his session cookie to impersonate another user or to perform actions as another user. All session parameters are signed with a random secret every time the application first runs and cookies passed to the application is validated on the server side to ensure they are valid and not tampered with.

W4-SQL :		It is not possible to perform SQL injection attempts via form submissions. 

- User inputs to the web application are sanitized server side before passing to server 4. Server 4 uses parameterized SQL queries to prevent code injection through malformed inputs.

W5-VALIDATE :	Form inputs are sanitized and validated

- Login and registration forms are validated for password length and empty fields both front and backend. Inputs are sanitized too in case if there are any special characters used.

W6-OTP :		Even if an attacker has access to a user’s login credentials, he will not be able to login without gaining access to the user’s 2FA device.

- Every login is accompanied by a one-time password (OTP) check, which can only be retrieved with the user’s secondary factor authenticating device (Google Authenticator on the user’s mobile device).

## Functional Claims

F1-2FA :		New registration requires 2FA (OTP with Google Authenticator) to be configured, before the researcher can access search features with the new account.

- A new registration is followed by a prompt to link the account to the user’s Google Authenticator mobile application, where OTP will be sent for every login. The OTP configuration process must be completed before a user is able to perform any other tasks in the application.

F2-ROBOT :		Recaptcha is implemented for registration to reduce spam. It’s based off Google Recaptcha V2 api.

- Captcha prevents brute forcing of parameters by scripts and bots and encourage human testing. This reduces traffic on the server side and minimize server load.

F3-ADMIN :		It is not possible for a normal researcher to execute the action of an admin researcher, namely, to view all request for permission, approve and decline request for permission.

- Before performing an admin action, the access level of the researcher (e.g. normal or admin) is checked, and the admin action will only be followed through if the researcher is verified as an admin.

F4-PERMISSIONS :	It is not possible to retrieve search results without first obtaining permission(s) for searching various conditions.

- Researchers that sign up are required to apply for permission to condition categories pertaining to their field of study. Application for a category must be approved by an admin researcher before the new researcher can gain access to view datasets pertaining to the category. Checks are also done before search to ensure that the conditions selected by the researcher are those that are granted to him/her. 

F5-KANON :		It is not possible to identify a record from the result set to an individual patient.

- The Medical Query Research Portal allows for displaying of information from the database, as long as that information cannot be used to identify individuals.  This is achieved by enforcing the k-anonymity property of the result sets through data anonymization algorithms. It is to note that data files will not be treated as an identifier to a patient, as it is out of the project’s focus (as discussed during consultations) to run k-anonymization algorithms for the data files. As such, a pseudo sensitivity trigger will be used to decide if the data file is deemed as private or disclosable. The data files will still be generalized to some extent to maintain business and functional realism.

F6-DOWNLOAD : 	It is not possible to reuse a download link to retrieve the intended data file.

- A one-time download link to a data file upon query is generated for the research to download should he/she wishes to. Upon activation, the link will be destroyed. It is impossible to retrieve the same file with the same link. In the case where a malicious researcher brute-forces download links to retrieve data, the security concerns and implications are trivial as files will not identify the patient nor is sensitive (it will be unavailable in this case).
