component accessors=true {

    function init( any departmentService, any roleService, any beanFactory ) {
        variables.departmentService = departmentService;
        variables.roleService = roleService;
        variables.beanFactory = beanFactory;
        variables.users = { };

		// since services are cached, user data will be persisted
		// ideally, this would be saved elsewhere, e.g. database

		// FIRST
        var user = variables.beanFactory.getBean( "userBean" );
		user.setId("1");
		user.setFirstName("Admin");
		user.setLastName("User");
		user.setEmail("admin@mysite.com");
		user.setDepartmentId("1");
		user.setDepartment(variables.departmentService.get("1"));
		user.setRoleId("1");
		user.setRole(arguments.roleService.get("1"));
		// set the password.  typically the hash and salt would be in a database.
		// avoid plain text passwords in files or the database
		var passwordHashSalt = hashPassword('admin');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// SECOND
		user = variables.beanFactory.getBean( "userBean" );
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(variables.departmentService.get("2"));
		user.setRoleId("2");
		user.setRole(arguments.roleService.get("2"));
		passwordHashSalt = hashPassword('larryrulz');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// THIRD
		user = variables.beanFactory.getBean( "userBean" );
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(variables.departmentService.get("3"));
		user.setRoleId("2");
		user.setRole(arguments.roleService.get("2"));
		passwordHashSalt = hashPassword('moerulz');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// BEN
		variables.nextid = 4;

        return this;
    }

    function delete( string id ) {
        structDelete( variables.users, id );
    }

    function get( string id ) {
        var result = 0;
        if ( len( id ) && structKeyExists( variables.users, id ) ) {
            result = variables.users[ id ];
        } else {
            result = variables.beanFactory.getBean( "userBean" );
        }
        return result;
    }

    function getByEmail( string email ) {
        var result = "";
        if ( len( email ) ) {
            for ( var userId in variables.users ) {
                var user = variables.users[ userId ];
                if ( !comparenocase( email, user.getEmail() ) ) {
                    result = user;
                }
            }
        }
        if ( !isStruct( result ) ) {
            result = variables.beanFactory.getBean( "userBean" );
        }
        return result;
    }

    function list() {
        return variables.users;
    }

    function validate( any user, string firstName = "", string lastName = "", string email = "",
                       string departmentId = "", string roleId = "", string password = "" ) {
        var aErrors = [ ];
        var userByEmail = getByEmail( email );
        var department = variables.departmentService.get( departmentId );
        var role = variables.roleService.get( roleId );

        // validate password for new or existing user
        if ( !user.getId() && !len( password ) ) {
            arrayAppend( aErrors, "Please enter a password for the user" )
        } else if ( len( password ) ) {
            aErrors = checkPassword( user = user, newPassword = password, retypePassword = password );
        }
        // validate first and last name
        if ( !len( user.getFirstName() ) && !len( firstName ) ) {
            arrayAppend( aErrors, "Please enter the user's first name" );
        }
        if ( !len( user.getLastName() ) && !len( lastName ) ) {
            arrayAppend( aErrors, "Please enter the user's last name" );
        }
        // validate email address
        if ( !len( user.getEmail() ) && !len( email ) ) {
            arrayAppend( aErrors, "Please enter the user's email address" );
        } else if ( len( email ) && !isEmail( email ) ) {
            arrayAppend( aErrors, "Please enter a valid email address" );
        } else if ( len( email ) && !compare( email, userByEmail.getEmail() ) ) {
            arrayAppend( aErrors, "A user already exists with this email address, please enter a new address." );
        }
        // validate department ID
        if ( !len( departmentId ) || !isNumeric( departmentId ) || !department.getId() ) {
            arrayAppend( aErrors, "Please select a department" );
        }
        // validate role ID
        if ( !len( roleId ) || !isNumeric( roleId ) || !role.getId() ) {
            arrayAppend( aErrors, "Please select a role" );
        }

        return aErrors;
    }

    function save( any user ) { 
        if ( user.getId() ) {
            variables.users[ user.getId() ] = user;
        } else {
            // new user
            // BEN
            lock type="exclusive" name="setNextID" timeout="10" throwontimeout="false" {
                var newId = variables.nextId;
                ++variables.nextId;
            }
            // END BEN
            user.setId( newId );
            variables.users[ newId ] = user;
        }
    }

/*
security functions were adapted from Jason Dean's security series
http://www.12robots.com/index.cfm/2008/5/13/A-Simple-Password-Strength-Function-Security-Series-4.1
http://www.12robots.com/index.cfm/2008/5/29/Salting-and-Hashing-Code-Example--Security-Series-44
http://www.12robots.com/index.cfm/2008/6/2/User-Login-with-Salted-and-Hashed-passwords--Security-Series-45
*/

    function hashPassword( string password ) {
        var returnVar = { };
        returnVar.salt = createUUID();
        returnVar.hash = hash( password & returnVar.salt, "SHA-512" );
        return returnVar;
    }

    function validatePassword( any user, string password ) {
        // catenate password and user salt to generate hash
        var inputHash = hash( trim( password ) & trim( user.getPasswordSalt() ), "SHA-512" );
        // password is valid if hash matches existing user hash
        return !compare( inputHash, user.getPasswordHash() );
    }

    function checkPassword( any user, string currentPassword = "",
                            string newPassword = "", string retypePassword = "" ) {
		// Initialize return variable
		var aErrors = arrayNew(1);
		var inputHash = '';
		var count = 0;

		// if the password fields to not have values, add an error and return
		if (not len(arguments.newPassword) or not len(arguments.retypePassword)) {
			arrayAppend(aErrors, "Please fill out all form fields");
			return aErrors;
		}

		if (len(arguments.currentPassword) and isObject(user)) {
			// If the user is changing their password, compare the current password to the saved hash
			inputHash = hash(trim(arguments.currentPassword) & trim(user.getPasswordSalt()), 'SHA-512');

			/* Compare the inputHash with the hash in the user object. if they do not match,
				then the correct password was not passed in */
			if (not compare(inputHash, user.getPasswordHash()) IS 0) {
				arrayAppend(aErrors, "Your current password does not match the current password entered");
				// Return now, there is no point testing further
				return aErrors;
			}

			// Compare the current password to the new password, if they match add an error
			if (compare(arguments.currentPassword, arguments.newPassword) IS 0)
				arrayAppend(aErrors, "The new password can not match your current password");
		}

		// Check the password rules
		// *** to change the strength of the password required, uncomment as needed

		// Check to see if the two passwords match
		if (not compare(arguments.newPassword, arguments.retypePassword) IS 0) {
			arrayAppend(aErrors, "The new passwords you entered do not match");
			// Return now, there is no point testing further
			return aErrors;
		}

		// If the password is more than X and less than Y, add an error.
		if (len(arguments.newPassword) LT 8)// OR Len(arguments.newPassword) GT 25
			arrayAppend(aErrors, "Your password must be at least 8 characters long");// between 8 and 25

		// Check for atleast 1 uppercase or lowercase letter
		/* if (NOT REFind('[A-Z]+', arguments.newPassword) AND NOT REFind('[a-z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 letter"); */

		// check for at least 1 letter
		if (reFind('[A-Z]+',arguments.newPassword))
			count++;
		if (reFind('[a-z]+', arguments.newPassword))
			count++;
		if (not count)
			arrayAppend(aErrors, "Your password must contain at least 1 letter");

		// Check for at least 1 uppercase letter
		/*if (NOT REFind('[A-Z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 uppercase letter");*/

		// Check for at least 1 lowercase letter
		/*if (NOT REFind('[a-z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 lowercase letter");*/

		// check for at least 1 number or special character
		count = 0;
		if (reFind('[1-9]+', arguments.newPassword))
			count++;
		if (reFind("[;|:|@|!|$|##|%|^|&|*|(|)|_|-|+|=|\'|\\|\||{|}|?|/|,|.]+", arguments.newPassword))
			count++;
		if (not count)
			arrayAppend(aErrors, "Your password must contain at least 1 number or special character");

		// Check for at least 1 numeral
		/*if (NOT REFind('[1-9]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 number");*/

		// Check for one of the predfined special characters, you can add more by seperating each character with a pipe(|)
		/* if (NOT REFind("[;|:|@|!|$|##|%|^|&|*|(|)|_|-|+|=|\'|\\|\||{|}|?|/|,|.]+", arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 special character"); */

		// Check to see if the password contains the username
		if (len(user.getEmail()) and arguments.newPassword CONTAINS user.getEmail())
			arrayAppend(aErrors, "Your password cannot contain your email address");

		// Check to see if password is a date
		if (isDate(arguments.newPassword))
			arrayAppend(aErrors, "Your password cannot be a date");

		// Make sure password contains no spaces
		if (arguments.newPassword CONTAINS " ")
			arrayAppend(aErrors, "Your password cannot contain spaces");

        return aErrors;
    }

    /* cflib.org */

    /**
* Tests passed value to see if it is a valid e-mail address (supports subdomain nesting and new top-level domains).
* Update by David Kearns to support '
* SBrown@xacting.com pointing out regex still wasn't accepting ' correctly.
* Should support + gmail style addresses now.
* More TLDs
* Version 4 by P Farrel, supports limits on u/h
* Added mobi
* v6 more tlds
*
* @param str      The string to check. (Required)
* @return Returns a boolean.
* @author Jeff Guillaume (SBrown@xacting.comjeff@kazoomis.com)
* @version 7, May 8, 2009
*/
    function isEmail(str) {
        return REFindNoCase("^['_a-z0-9-\+]+(\.['_a-z0-9-\+]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|asia|biz|cat|coop|info|museum|name|jobs|post|pro|tel|travel|mobi))$",str) &&
            len( listFirst(str, "@") ) <= 64 &&
            len( listRest(str, "@") ) <= 255;
    }

}
