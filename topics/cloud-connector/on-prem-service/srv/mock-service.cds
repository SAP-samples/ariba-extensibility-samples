using com.ariba.mock as mck from '../db/data-model';

service MockService {

    entity Suppliers as projection on mck.Suppliers; 
    entity SourcingProjects as projection on mck.SourcingProjects; 

}