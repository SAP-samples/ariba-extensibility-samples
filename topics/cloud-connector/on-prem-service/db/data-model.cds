namespace com.ariba.mock;

entity Suppliers {
    key ID: String;
    name: String;
    ANId: String;
    RegistrationStatus: String;
    QualificationStatus: String;
}

entity SourcingProjects {
    key ID: String;
    Title: String;
    Status: String;
    ParentDocumentId: String;
    ExternalSystemCorrelationId: String;
    OwnerEmail: String;
}