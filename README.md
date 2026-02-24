This project has the goal to solve a bug with Firebase Authentication service.

## What's wrong ?

As a user, when you want to change your email you receive an email to verify said email, you click on it and the system tells you that your email changed correctly but in the authentication panel the email switch back to your previous email.

**Schema:**
Change email -> receive 1 email (instead of 2, one for verify the new and one to notify the change) -> Verify email -> Successfully updated -> System come back to the previous one email
