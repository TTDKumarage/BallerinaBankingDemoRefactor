import ballerina/http;
// import ballerina/io;
import ballerina/random;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerina/log;

configurable string DB_HOST = ?;
configurable string DB_USER = ?;
configurable string DB_PASSWORD = ?;
configurable string DB_NAME = ?;
configurable int DB_PORT = ?;

const string jsonFilePath = "./requests.json";

service /cms on new http:Listener(9090) {


    private final mysql:Client db;
    function init() returns error? {
        self.db = check new (DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, DB_PORT);
    }

    resource function post creditcardrequest_application(@http:Payload json request) returns json|error {
    int application_id = check random:createIntInRange(10000, 1000000);
    string status = "inapproval";
    string message = "Credit card request is currently being processed for approval";

    if request.primary_applicant is json {

        json primaryApplicant = check request.primary_applicant;
        json coApplicant = check request.co_applicant;
        string primaryCustomerId = check primaryApplicant.customer_id;
        string primaryName = check primaryApplicant.name;
        string primaryEmail = check primaryApplicant.email;
        string primaryPhone = check primaryApplicant.phone;
        string primaryAddress = check primaryApplicant.address;
        int primaryAnnualIncome = check primaryApplicant.annual_income;
        string primaryEmploymentStatus = check primaryApplicant.employment_status;

        string coCustomerId = check coApplicant.customer_id;
        string coName = check coApplicant.name;
        string coEmail = check coApplicant.email;
        string coPhone = check coApplicant.phone;
        string coAddress = check coApplicant.address;
        int coAnnualIncome = check coApplicant.annual_income;
        string coEmploymentStatus = check coApplicant.employment_status;

        sql:ExecutionResult result = check self.db->execute(`
            INSERT INTO application_requests (application_id, request_type, customer_id, name, email, phone, address, annual_income, employment_status, 
                                              co_customer_id, co_name, co_email, co_phone, co_address, co_annual_income, co_employment_status, status)
            VALUES (${application_id}, 'co-applicant', ${primaryCustomerId}, ${primaryName}, ${primaryEmail}, ${primaryPhone}, ${primaryAddress}, 
                    ${primaryAnnualIncome}, ${primaryEmploymentStatus}, ${coCustomerId}, ${coName}, ${coEmail}, ${coPhone}, 
                    ${coAddress}, ${coAnnualIncome}, ${coEmploymentStatus}, ${status});
        `);

        if request.credit_limit is int {
        int primaryCreditLimit = check primaryApplicant.credit_limit;
        sql:ExecutionResult updateResult = check self.db->execute(`
            UPDATE application_requests 
            SET credit_limit = ${primaryCreditLimit}
            WHERE application_id = ${application_id};
        `);

        if request.card_type is string {
        string cardType = check primaryApplicant.card_type;
        sql:ExecutionResult updateResult2 = check self.db->execute(`
            UPDATE application_requests 
            SET card_type = ${cardType}
            WHERE application_id = ${application_id};
        `);
    }

    if request.requested_credit_limit is int {
        int requestedCreditLimit = check primaryApplicant.requested_credit_limit;
        sql:ExecutionResult updateResult3 = check self.db->execute(`
            UPDATE application_requests 
            SET requested_credit_limit = ${requestedCreditLimit}
            WHERE application_id = ${application_id};
        `);
    }
    }

    } else {
        string customerId = check request.customer_id;
        string name = check request.name;
        string email = check request.email;
        string phone = check request.phone;
        string address = check request.address;
        int annualIncome = check request.annual_income;
        string employmentStatus = check request.employment_status;

        sql:ExecutionResult result = check self.db->execute(`
            INSERT INTO application_requests (application_id, request_type, customer_id, name, email, phone, address, annual_income, employment_status, status)
            VALUES (${application_id}, 'single', ${customerId}, ${name}, ${email}, ${phone}, ${address}, 
                    ${annualIncome}, ${employmentStatus}, ${status});
        `);

        if request.credit_limit is int {
        int creditLimit = check request.credit_limit;
        sql:ExecutionResult updateResult = check self.db->execute(`
            UPDATE application_requests 
            SET credit_limit = ${creditLimit}
            WHERE application_id = ${application_id};
        `);
         }
    }

      if request.card_type is string {
        string cardType = check request.card_type;
        sql:ExecutionResult updateResult2 = check self.db->execute(`
            UPDATE application_requests 
            SET card_type = ${cardType}
            WHERE application_id = ${application_id};
        `);
    }

    if request.requested_credit_limit is int {
        int requestedCreditLimit = check request.requested_credit_limit;
        sql:ExecutionResult updateResult3 = check self.db->execute(`
            UPDATE application_requests 
            SET requested_credit_limit = ${requestedCreditLimit}
            WHERE application_id = ${application_id};
        `);
    }

    return {
        "application_id": application_id.toString(),
        "status": status,
        "message": message
    };
}



    // Get Status function
resource function get creditcardrequest_application/[string application_id]() returns json|error {
    sql:ParameterizedQuery query = `SELECT application_id, status FROM application_requests WHERE application_id = ${application_id}`;
    stream<record {int application_id; string status;}, sql:Error?> resultStream = self.db->query(query);
record {|
        record {int application_id; string status;} value;
    |}|sql:Error? result = resultStream.next();

    check resultStream.close();

    if (result is record {|
        record {int application_id; string status;} value;
    |}) {
        json response = {
            "application_id": result.value.application_id.toString(),
            "status": result.value.status,
            "message": "Credit card request (Application ID: " + result.value.application_id.toString() + ") is in " + result.value.status
        };

        return response;
    } else if (result is sql:Error) {
        log:printError("Next operation on the stream failed!:" + result.message());
        return error(result.message());
    } else {
        return error("Invalid application Id");
    }
}

    //update status function
    // isolated resource function put updateStatus/[string application_id](@http:Payload json updateStatus) returns json|error {
    //     json|io:Error applicationRequests = io:fileReadJson(jsonFilePath);

    //     if applicationRequests is json[] {
    //         foreach var item in applicationRequests {
    //             if (item is json) {
    //                 string applicationIdFromDataSet = (check item.application_id).toString();

    //                 if (applicationIdFromDataSet == application_id) {
    //                     string status = (check updateStatus.status).toString();
    //                     map<json> mapResult = check item.ensureType();
    //                     mapResult["status"] = status;

    //                     json _ = check io:fileWriteJson(jsonFilePath, applicationRequests);

    //                     return item;
    //                 }
    //             }
    //         }
    //     }
    //         return error("Invalid application Id");
    // }

    // isolated resource function put updateStatus/[string application_id](@http:Payload json updateStatus) returns json|error {
    // // Extract status from the payload
    // string status = check updateStatus.status;

    // // Define the query to update the application status
    // sql:ParameterizedQuery updateQuery = `UPDATE application_requests SET status = ${status} WHERE application_id = ${application_id}`;

    // // Execute the update query
    // sql:ExecutionResult updateResult = check self.db->execute(updateQuery);

    // // Check if the update was successful
    // if (updateResult.affectedRowCount == 0) {
    //     return error("Invalid application Id");
    // }

    // // Define the query to fetch the updated application details
    // sql:ParameterizedQuery selectQuery = `SELECT * FROM application_requests WHERE application_id = ${application_id}`;

    // // Execute the select query
    // stream<record {int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
    //                int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
    //                string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;}, sql:Error?> resultStream = self.db->query(selectQuery);

    // // Fetch the record
    // record {int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
    //         int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
    //         string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;}|sql:Error? result = resultStream.next();

    // // Close the result stream
    // check resultStream.close();

    // if (result is record {
    //     int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
    //     int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
    //     string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;
    // }) {
    //     // Construct the response based on the request type
    //     json response;
    //     if (result.request_type == "co-applicant") {
    //         response = {
    //             "application_id": result.application_id.toString(),
    //             "status": result.status,
    //             "message": "Credit card request (Application ID: " + result.application_id.toString() + ") is in " + result.status,
    //             "card_type": result.card_type ?: (),
    //             "primary_applicant": {
    //                 "customer_id": result.customer_id,
    //                 "name": result.name,
    //                 "email": result.email,
    //                 "phone": result.phone,
    //                 "address": result.address,
    //                 "credit_limit": result.credit_limit ?: result.requested_credit_limit,
    //                 "annual_income": result.annual_income,
    //                 "employment_status": result.employment_status
    //             },
    //             "co_applicant": {
    //                 "customer_id": result.co_customer_id ?: (),
    //                 "name": result.co_name ?: (),
    //                 "email": result.co_email ?: (),
    //                 "phone": result.co_phone ?: (),
    //                 "address": result.co_address ?: (),
    //                 "annual_income": result.co_annual_income ?: (),
    //                 "employment_status": result.co_employment_status ?: ()
    //             }
    //         };
    //     } else {
    //         response = {
    //             "application_id": result.application_id.toString(),
    //             "status": result.status,
    //             "message": "Credit card request (Application ID: " + result.application_id.toString() + ") is in " + result.status,
    //             "card_type": result.card_type ?: (),
    //             "customer_id": result.customer_id,
    //             "name": result.name,
    //             "email": result.email,
    //             "phone": result.phone,
    //             "address": result.address,
    //             "credit_limit": result.credit_limit ?: result.requested_credit_limit,
    //             "annual_income": result.annual_income,
    //             "employment_status": result.employment_status
    //         };
    //     }

    //     return response;
    // } else if (result is sql:Error) {
    //     log:printError("Next operation on the stream failed!:" + result.message());
    //     return error(result.message());
    // } else {
    //     return error("Invalid application Id");
    // }
    // }

    isolated resource function put updateStatus/[string application_id](@http:Payload json updateStatus) returns json|error {
    // Extract status from the payload
    string status = check updateStatus.status;

    // Define the query to update the application status
    sql:ParameterizedQuery updateQuery = `UPDATE application_requests SET status = ${status} WHERE application_id = ${application_id}`;

    // Execute the update query
    sql:ExecutionResult updateResult = check self.db->execute(updateQuery);

    // Check if the update was successful
    if (updateResult.affectedRowCount == 0) {
        return error("Invalid application Id");
    }

    // Define the query to fetch the updated application details
    sql:ParameterizedQuery selectQuery = `SELECT * FROM application_requests WHERE application_id = ${application_id}`;

    // Execute the select query
    stream<record {int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
                   int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
                   string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;}, sql:Error?> resultStream = self.db->query(selectQuery);

    // Fetch the record
    record {|
        record {int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
                int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
                string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;} value;
    |}|sql:Error? result = resultStream.next();

    // Close the result stream
    check resultStream.close();

    if (result is record {|
        record {int application_id; string status; string request_type; string customer_id; string name; string email; string phone; string address; 
                int? credit_limit; int annual_income; string employment_status; string? co_customer_id; string? co_name; string? co_email; 
                string? co_phone; string? co_address; int? co_annual_income; string? co_employment_status; string? card_type; int? requested_credit_limit;} value;
    |}) {
        // Map result into structure
        json response;
        if (result.value.request_type == "co-applicant") {
            response = {
                "application_id": result.value.application_id.toString(),
                "status": result.value.status,
                "message": "Credit card request (Application ID: " + result.value.application_id.toString() + ") is in " + result.value.status,
                "card_type": result.value.card_type ?: (),
                "primary_applicant": {
                    "customer_id": result.value.customer_id,
                    "name": result.value.name,
                    "email": result.value.email,
                    "phone": result.value.phone,
                    "address": result.value.address,
                    "credit_limit": result.value.credit_limit,
                    "requested_credit_limit": result.value.requested_credit_limit,
                    "annual_income": result.value.annual_income,
                    "employment_status": result.value.employment_status
                },
                "co_applicant": {
                    "customer_id": result.value.co_customer_id ?: (),
                    "name": result.value.co_name ?: (),
                    "email": result.value.co_email ?: (),
                    "phone": result.value.co_phone ?: (),
                    "address": result.value.co_address ?: (),
                    "annual_income": result.value.co_annual_income ?: (),
                    "employment_status": result.value.co_employment_status ?: ()
                }
            };
        } else {
            response = {
                "application_id": result.value.application_id.toString(),
                "status": result.value.status,
                "message": "Credit card request (Application ID: " + result.value.application_id.toString() + ") is in " + result.value.status,
                "card_type": result.value.card_type ?: (),
                "customer_id": result.value.customer_id,
                "name": result.value.name,
                "email": result.value.email,
                "phone": result.value.phone,
                "address": result.value.address,
                "credit_limit": result.value.credit_limit,
                "requested_credit_limit": result.value.requested_credit_limit,
                "annual_income": result.value.annual_income,
                "employment_status": result.value.employment_status
            };
        }

        return response;
    } else if (result is sql:Error) {
        log:printError("Next operation on the stream failed!:" + result.message());
        return error(result.message());
    } else {
        return error("Invalid application Id");
    }
}
}
