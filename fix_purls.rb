require 'ontologies_linked_data'
require 'ncbo_annotator'
require_relative 'config/config'
require_relative 'config/environments/production'
# require_relative 'config/environments/stage'


purl_client = LinkedData::Purl::Client.new


# acronyms = ["AAO", "ABA-AMB", "ACGT-MO", "AI-RHEUM", "APAONTO", "ATC", "AURA", "BCGO", "BCTEO", "BHN", "BILA",
#             "CANONT", "CCO", "CCON", "CHD", "CHEMBIO", "CLIN-EVAL", "CNO", "CO", "CO-WHEAT", "CPRO", "CPTH", "CRISP",
#             "CTONT", "DC-CL", "DIAGONT", "DIKB", "DOCCC", "DSO", "DWC-TEST", "ELIG", "EPILONT", "EPSO", "ERO", "FB-SP",
#             "FIRE", "FLO", "FLU", "GCC", "GENE-CDS", "GENETRIAL", "GEOSPECIES", "GEXO", "GLYCANONT", "GLYCOPROT", "GMO",
#             "GPI", "GRO-CPD", "GRO-CPGA", "HCPCS-HIMC", "HIMC-CPT", "HINO", "HIV", "HOM-TEST", "I2B2-LOINC", "ICD0",
#             "ICD09", "ICD11-BODYSYSTEM", "IDOMAL", "IEV", "IMMDIS", "IMR", "LHN", "LSM", "MCCL", "MIXSCV", "MPO", "MS",
#             "MSTDE", "MSTDE-FRE", "NBO", "NCC", "NCCO", "NEOMARK3", "NEOMARK4", "NHSQI2009", "NIC", "NONRCTO", "OBOREL",
#             "OBR-Scolio", "OFP", "OGSF", "OMIT", "ONTF", "ONTOAD", "ONTODM-CORE", "OntoOrpha", "ORTHO", "PHARMGKB",
#             "PHENOMEBLAST", "PHENOSCAPE-EXT", "PHYFIELD", "PIERO", "PLATSTG", "PPIO", "PRO-ONT", "PROVO", "PSDS",
#             "PSIMOD", "PTRANS", "RBSCI", "RCTONT", "RETO", "REXO", "RGMU", "RGMU2", "RNIMU", "SBRO", "SENTI", "STY",
#             "TAXRANK", "TEST-PROD", "TEST1015", "TESTONTO", "TESTONTO2", "TESTONTOO", "TST-PAUL2", "TTTTHHHH", "TYPON",
#             "UDEF", "UNITSONT", "VBCV", "WB-BT", "WB-LS", "WB-PHENOTYPE", "WH", "WSIO", "XEO", "ZIP3", "ZIP5"]


# acronyms = ["HOM-PROCS2.owl", "HOM-DXVCODES2.owl", "HOM-ICD9.owl", "HOM-PROCS_OSHPD.owl", "HOM-ICD9-PROCS_OSHPD.owl",
#             "HOM-ICD9-ECODES_OSHPDowl", "HOM-ICD9_DXandVCODES_OSHPD.owl", "HOM-MDCDRG_OSHPD.owl",
#             "HOM-ICD9-ECODES_OSHPD.owl", "HOM-PROCS2", "HOM-PROCS2", "HOM-DXVCODES2", "FBbt", "FBdv", "FAO", "EMAP",
#             "ECO", "EV", "CL", "CHEBI", "DDANAT", "DOID", "MA", "BTO", "ProPreO", "MOD", "MI", "PW", "MPATH", "TO",
#             "EO", "MFO", "MAO", "TGMA", "EHDA", "EHDAA", "MP", "FBbi", "CARO", "FBsp", "SOPHARM", "PRO", "SNPO",
#             "ClinicalTrialOntology", "basic-vertebrate-gross-anatomy", "RID", "ZFA", "amino-acid", "WBbt", "WBls",
#             "SEP", "SBO", "OBO_REL", "REX", "SPD", "birnlex", "MHC", "nif", "GRO", "TTO", "BSPO", "MIRO", "OCRe", "GO",
#             "ENVO", "WBPhenotype", "TADS", "BOOTStrep", "PATO", "SO", "TAO", "UO", "YPO", "IDO", "TRANS", "XAO", "ATMO",
#             "OGI", "ICD-9", "BRO", "DC_CL", "EP", "BPMetadata", "ECG", "RS", "DermLex", "VO", "MAT", "SPO", "BHO", "HP",
#             "OBI", "MO", "FHHO", "OPB", "EFO", "NEMO"]

# acronyms = ["HOM-PROCS2", "TADS", "HOM", "ABA", "CLKB", "CST", "ICPC", "BFO", "PEO", "SYMP", "SitBAC", "PLO", "APO",
#             "MeGO", "gsontology", "NIF_Dysfunction", "ATO", "Field", "LDA", "GAZ", "SSO", "IAO", "LNC", "PDQ", "OMIM",
#             "MEDLINEPLUS", "WHO", "SNOMEDCT", "NDFRT", "MSH", "PKO", "ICF", "KiSAO", "ICNP", "POL", "k2p", "NIF_Cell",
#             "TOK", "RXNORM", "MDR", "OGMS", "CTCAE", "ICPC2P", "AIR", "BTC", "NDDF", "ICD10PCS", "MDDB", "RCD", "GFO",
#             "GFO-Bio", "CHEMINF", "bioportal", "bioportal", "npo", "npo.owl", "bioportal.owl", "bro.owl", "BRO-Core",
#             "bro", "MS", "EDAM", "EDAM", "HL7", "PD_ST", "JERM", "CLO", "NCBITaxon", "pma", "NCIM", "IMGT", "TMA",
#             "bodysystem", "TMO", "ICECI", "MTHCH", "INO", "ICPS", "RNAO", "CPT", "ICD10", "FMA", "NCIt", "SIO",
#             "SNOMED-Ethnic-Group", "SNOMEDCT-MAS", "BAO", "EHDAA2", "BO", "DDI", "NIGO", "RoleO", "HL7_UCSF_DSCHRG",
#             "HL7_Dschrg", "HOM-ICD9"]


# acronyms = ["HOM-PROCS2/", "bioportal/", "bioportal", "npo/", "bro/", "MS/", "EDAM/", "apollo", "HOM_Discharge",
#             "UCSF_TSI_Discharge", "HOM_ICD9", "HOM_ICD9", "SNOMED-Clinical-Findings", "SNOMEDCT-CF", "CO_Wheat", "REPO",
#             "GALEN", "VAO", "ExO", "HPI", "vHOG", "UCare_Demographics", "UCare-Demographics", "TM-MER",
#             "TM-SIGNS-AND-SYMPTS", "TM-OTHER-FACTORS", "TM-CONST", "obi-device", "OGMD", "FDA-MedDevice", "HOM-EHS",
#             "PVOnto", "CELDAC", "PHARE", "1580", "AERO", "COA", "BP", "PO", "COR", "PR", "CMO", "XCO", "MMO",
#             "Chem2Bio2OWL", "PRePPO", "PhylOnt", "IxnO", "BDO", "OntoDT", "OMRSE", "HLTH_INDICS", "FBcv", "HUGO",
#             "CogPO", "ICD10CM", "NMR", "CSP", "OBOE", "oboe-sbc", "NeuMORE", "MCBCC", "LiPrO", "NeoMarkOntology",
#             "ACGT", "BT", "CDAO", "CPTAC", "OGR", "ODGI", "CBO", "CPR", "pseudo", "SAO", "ZEA", "UBERON", "fged-obi",
#             "obi-fged", "ICD9_PROCEDURES", "OPL", "HOMERUN_UHC", "BiositemapIM", "BRO-Activity", "BRO-AreaOfResearch",
#             "BRO-Chinese", "cogat", "EMO", "HC", "OntoDM", "NCBI_NMOsp", "invertebrata", "VT", "IDOBRU"]

# acronyms = ["HOM-DATASOURCE_OSHPD", "EPIC-SRC", "HOM-EPIC", "HOMERUN", "HOM-TX", "HPIO", "SHR", "MFOEM", "PedTerm",
#             "AEO", "OAE", "FYPO", "HOM-CPT", "SYN", "DATASRC-ORTHO", "HOM-ORTHO", "vivo", "OPB.properties",
#             "proftest.4205", "PO_PAE", "PO_PSDS", "GRO_CPD", "GRO_CPGA", "VSAO", "RH-MESH", "BAO-GPCR", "FMA-SUBSET",
#             "COSTART", "ORDO", "FB-CV", "cms.36739", "chi.76398", "chi.41353", "I9I10CMMOST", "project", "DTVPrecision",
#             "bibliographic", "dcterms", "foaf", "SciRes", "BRIDG", "ICD9CM-PROC", "CPT-mod", "SWEET",
#             "cms.29622", "HOM-CHI", "nhds.7763", "NIF-RTH", "shrine.20924", "IDODEN", "gs1", "MEDO", "IFAR", "PathLex",
#             "journal-test", "testvdb", "UCSF-ICD910CM", "Pizza-Example", "OPE", "NCBO_TEST_NOTES", "CABRO", "MTHMSTFRE",
#             "GCO", "pomoc", "bco", "OVAE", "GOWGP_B", "BOF", "RNPRIO", "ONL-DP", "SSE", "IMGT-ONTOLOGY", "InterNano",
#             "OBI_BCGO", "suicideo", "CARD", "MISHA_TEST2", "TEST-ONT-0-0", "MSV", "MATO", "STATO", "ELIXHAUSER",
#             "SNOMED_TEST", "BWT", "ZC", "AI", "NIFCELL", "NIFDYS", "MESH"]

# acronyms = ["OBCS", "FLOPO", "HUPSON", "NMOSP_1_6", "NMOSP", "CCC", "DEMOGRAPH", "GLOB", "SNOMED_ANATOMY", "SNOMED_ORG",
#             "SNOMED_CF", "ICO", "BWT2", "NGSONTO", "HIVO004", "OGG", "TESTING", "RCTOntology", "CEEROntology",
#             "dikb-evidence", "ICDO3", "QIBO", "HOM-OSHPD-SC", "SRC-OSHPDSC", "test_pradip_purl", "NDF-RT", "envo_153",
#             "HOM-ORTHOSURG", "eufut", "MCV", "OBI_IEDB_view", "HOM-I9I10MAPS", "MF", "VANDF", "GWAS_EFO_SKOS", "NatPrO",
#             "HSDB_OCRe", "test-111", "OoEVV", "HOM-ICU", "CareLex", "DiagnosticOnt", "Phys_Med_Rehab", "PMR",
#             "ICD9toICD10PCS", "HOM-DXandVCODES_OSHPD", "HOM_HARVARD", "HOM-PROCS_OSHPD", "HOM-ICD9CM-ECODES",
#             "HOM-ICD9CM_PROCEDURES", "HOM-MDCDRG_OSHPD", "HOM_MDCs_DRGs", "HOM_EHS", "HOM-PCSTEST", "MESH-OWL", "PTSD",
#             "HOM-UPENN-MEDS", "HOM-UPENN_MEDS", "SDO", "SOY", "SPTO", "CanCO", "CTX", "QUDT", "HOM-UPENNMEDS", "WHOFRE",
#             "ICPCFRE", "MDRFRE", "thesaurus", "ontologia", "thealternativa", "SNMD_BDY", "SWO", "ICF-NoCodeLabel",
#             "testabbr", "bccl", "bccl1", "HOM-MEDABBS", "HOM-TESTKM", "HOM-I9CM", "HOM-MDCDRG", "NonRCTOntology",
#             "HOM-DEMOGR"]


# acronyms = ["uni-ece", "PFO", "PhenXTK", "HCPCS", "test.20230", "test.20930", "HOM-DATSRCTEST", "i2b2-patvisdims",
#             "homv2", "HOM-EPICI2B2", "ICD9CM", "TAHH", "TAHE", "HOM-I9PCS", "CAO", "HOM-UCARE", "EpilepOnto",
#             "HOM-DXPCS_MDCDRG", "HOM-PCS_OSHPD", "HOM-I9-ECODES", "HOM-VCODES_OSHPD", "HOM-SRCE_OSHPD", "UnitsOntology",
#             "HOM-OSHPD_UseCas", "pharmgkb-owl", "phenomeblast-owl", "CAMRQ", "tJADNI2", "BIOA3", "TestHDB", "tJADNI",
#             "BIOA", "UCBH", "BIOA2", "NeoMark", "MEO", "test-purl", "yipd", "BioModels", "CPO", "PhyMeRe", "onto",
#             "TEO", "test-1", "ADW", "HOM-OSHPD", "test.13773", "test.16355", "profectus.test.installation.21838",
#             "profectus.test.installation.21775", "profectus.test.installation.21934",
#             "profectus.test.installation.22027", "profectus.test.installation.21975",
#             "profectus.test.installation.22081", "profectus.test.installation.22611",
#             "profectus.test.installation.22704", "profectus.test.installation.22770",
#             "OntoDM-KDD"]

# acronyms = ["PhenX", "HOMICD910PCS-150", "dsfs", "HOM-I910TESTPLUS", "DwC", "HOM-DATSRCTESTo", "HOM-DATASRCTESTn",
#             "HOM-I910PCS-150", "HOM-ORTHOTEST", "test.8300", "HOM-OCHILDTEST", "OntoMA", "HOM-CLINIC", "DwC_test",
#             "UCSF_15", "UCSF_41", "profectus.deid.installation.27982", "profectus.deid.installation.28036",
#             "profectus.deid.installation.28409", "profectus.deid.installation.32434",
#             "profectus.deid.installation.21442", "HOM-OCC", "profectus.deid.installation.7616",
#             "profectus.deid.installation.6250", "DC_test", "CCONT", "profectus.deid.installation.14032",
#             "profectus.deid.installation.14522", "profectus.deid.installation.19214", "BIOA3v",
#             "profectus.deid.installation.3433", "profectus.deid.installation.16341", "RPO",
#             "profectus.deid.installation.11714", "profectus.deid.installation.19037",
#             "profectus.deid.installation.27298", "profectus.deid.installation.31807", "OBIws", "ooevv-tractTrace",
#             "ooevv-vaccine", "pco", "VSO", "profectus.oshpd.installation.5931", "NIF-Subcell", "DwC_translations",
#             "PabloTest", "ConsentOntology", "pablotest2", "prov-o", "oshpd.39537", "nhds.13469", "nhds.13896",
#             "HOM-NHDS", "ONSTR", "miRNAO", "chi.58970", "chi.61020", "chi.76831", "HOM-CMS", "Clinical_Eval",
#             "documentStatus", "geopolitical", "citation", "dcelements", "event", "FaBiO", "provenance", "skos",
#             "chi.20896", "NTDO", "oshpd.33038", "OntoKBCF", "HCPCS-mod", "chi.63559", "VariO", "NIAID-GSC-BRC",
#             "cms.11830", "HOM-CHICMS", "nhds.7622", "HOM-GLOB", "jnnn", "GlycO"]

# acronyms = ["shrine.20839", "shrine.20676", "chi.50064", "MetaCT", "ThomCan", "Genomic-CDS", "OntoPneumo", "bd-test2",
#             "avnguyen-test2", "Top-Menelas", "MCCV", "SemPhysKB-Human", "ZIP", "biocode", "PORO", "ATOL", "IDQA",
#             "TRAK", "UCSD", "mixs", "bao_gpcr", "TrOn", "MTHMST", "DermaO", "rsa", "DermO", "ECGT", "UCSFI9I10ALL",
#             "SBOLv", "DILIo", "Eligibility", "CHDWiki", "BOFrdf", "VTO", "PDO", "CSSO", "NHSQI", "SEDI", "SuicidO",
#             "ONL-MSA", "EDDA", "ONL-MR-DA", "ADO", "OntoVIP", "CHMO", "BdOK", "BOFf", "SBOL", "RadLex_v3.91",
#             "STNFRDRXDEMO", "OntoBioUSP", "Radlex3.9.1", "BNO", "DCO", "PROV", "BSAO", "HRDO", "SNMI", "FIX"]

LinkedData::Models::Ontology.all.each do |ont|
  ont.bring(:acronym)
  acronym = ont.acronym

  if (purl_client.purl_exists(acronym))
    puts "#{acronym} exists"
    purl_client.fix_purl(acronym)
  else
    puts "#{acronym} DOES NOT exist"
    purl_client.create_purl(acronym)
  end
end




# acronyms.each do |acronym|
#   purl_client.fix_purl(acronym)
# end
