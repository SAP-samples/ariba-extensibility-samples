module.exports = (srv) => {

    // Reply mock data for Suppliers...
    // srv.on ('READ', 'Suppliers', ()=>[
    //   { ID: "1", name:'ACME Ltd' },
    //   { ID: "2", name:'The Raven' },
    //   { ID: "3", name:'Eleonora' },
    //   { ID: "4", name:'Catweazle' },
    // ])  

    const {Suppliers} = cds.entities('com.ariba.mock')

}