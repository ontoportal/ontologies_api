require 'sinatra/base'

#  @options[:resource_index_location]  = "http://rest.bioontology.org/resource_index/"
#  @options[:filterNumber]             = true
#  @options[:isStopWordsCaseSensitive] = false
#  @options[:isVirtualOntologyId]      = true
#  @options[:levelMax]                 = 0
#  @options[:longestOnly]              = false
#  @options[:ontologiesToExpand]       = []
#  @options[:ontologiesToKeepInResult] = []
#  @options[:mappingTypes]             = []
#  @options[:minTermSize]              = 3
#  @options[:scored]                   = true
#  @options[:semanticTypes]            = []
#  @options[:stopWords]                = []
#  @options[:wholeWordOnly]            = true
#  @options[:withDefaultStopWords]     = true
#  @options[:withSynonyms]             = true
#  @options[:conceptids]               = []
#  @options[:mode]                     = :union
#  @options[:elementid]                = []
#  @options[:resourceids]              = []
#  @options[:elementDetails]           = false
#  @options[:withContext]              = true
#  @options[:offset]                   = 0
#  @options[:limit]                    = 10
#  @options[:format]                   = :xml
#  @options[:counts]                   = false
#  @options[:request_timeout]          = 300

module Sinatra
  module Helpers
    module ResourceIndexHelper

      def get_classes(params)
        # Assume request signature of the form:
        # classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]
        classes = []
        if params.key?("classes")
          class_hash = params["classes"]
          class_hash.each do |k,v|
            # Use 'k' as an ontology acronym, translate it to an ontology virtual ID.
            ont_id = get_ontology_virtual_id(k)
            next if ont_id == nil  # TODO: raise an exception?
            # Use 'v' as a CSV list of concepts (class ID)
            v.split(',').each do |class_id|
              classes.push("#{ont_id}/#{class_id}")
            end
          end
        end
        return classes
      end

      # TODO, change to an API call that will set ontology abbreviation to virtual ID mapping
      ONTOLOGY_ACRONYM_MAP = {'CBO' => 1158, 'FBdv' => 1016, 'NMR' => 1033, 'MSH' => 1351, 'ECG' => 1146, 'MOD' => 1041, 'PR' => 1062, 'MA' => 1000, 'TADS' => 1065, 'OBI' => 1123, 'SNPO' => 1058, 'ATMO' => 1099, 'BT' => 1134, 'BSPO' => 1078, 'geospecies' => 1247, 'CHEBI' => 1007, 'LHN' => 1024, 'MeGO' => 1257, 'pseudo' => 1135, 'WBls' => 1049, 'GO' => 1070, 'FHHO' => 1126, 'PO_PAE' => 1108, 'BILA' => 1114, 'OGI' => 1100, 'EFO' => 1136, 'OPB.properties' => 1141, 'SEP' => 1044, 'MEDLINEPLUS' => 1347, 'BTO' => 1005, 'MAT' => 1152, 'CARO' => 1063, 'NEMO' => 1321, 'REX' => 1043, 'FBsp' => 1064, 'birnlex' => 1089, 'OCRe' => 1076, 'TAO' => 1110, 'HAO' => 1362, 'TGMA' => 1030, 'IMR' => 1029, 'BHO' => 1116, 'BRO' => 1104, 'DC_CL' => 1144, 'HP' => 1125, 'FBbi' => 1023, 'EHDAA' => 1021, 'SBO' => 1046, 'ZFA' => 1051, 'TO' => 1037, 'LNC' => 1350, 'GRO' => 1082, 'PATO' => 1107, 'TTO' => 1081, 'WBbt' => 1048, 'ZEA' => 1050, 'GRO_CPD' => 1047, 'PDQ' => 1349, 'OPL' => 1190, 'EO' => 1036, 'SO' => 1109, 'CPTAC' => 1192, 'NDFRT' => 1352, 'CPR' => 1059, 'pro-ont' => 1052, 'CST' => 1341, 'BCGO' => 1304, 'ICPC' => 1344, 'SOPHARM' => 1061, 'SNOMEDCT' => 1353, 'EHDA' => 1022, 'FIX' => 1014, 'SYMP' => 1224, 'XAO' => 1095, 'OBO_REL' => 1042, 'EV' => 1013, 'DermLex' => 1149, 'IDOMAL' => 1311, 'PEO' => 1335, 'ATO' => 1370, 'MFO' => 1027, 'WHO' => 1354, 'IEV' => 1011, 'EMAP' => 1010, 'FBbt' => 1015, 'AAO' => 1090, 'HC' => 1020, 'BPMetadata' => 1148, 'PO_PSDS' => 1038, 'NCBITaxon' => 1132, 'HOM' => 1328, 'FAO' => 1019, 'ABA' => 1290, 'WBPhenotype' => 1067, 'ENVO' => 1069, 'GALEN' => 1055, 'BFO' => 1332, 'LiPrO' => 1183, 'MAO' => 1026, 'ACGT' => 1130, 'ClinicalTrialOntology' => 1060, 'UO' => 1112, 'Field' => 1369, 'ODGI' => 1086, 'SPD' => 1091, 'FBcv' => 1017, 'OMIM' => 1348, 'SPO' => 1122, 'EP' => 1142, 'CDAO' => 1128, 'VO' => 1172, 'MHC' => 1088, 'APO' => 1222, 'SBRO' => 1249, 'ProPreO' => 1039, 'MS' => 1105, 'MI' => 1040, 'SitBAC' => 1237, 'DDANAT' => 1008, 'SAO' => 1068, 'OGR' => 1087, 'RS' => 1150, 'ICD9CM' => 1101, 'CLO' => 1314, 'DOID' => 1009, 'TRANS' => 1094, 'nif' => 1084, 'MP' => 1025, 'MO' => 1131, 'PW' => 1035, 'amino-acid' => 1054, 'bvga' => 1056, 'ECO' => 1012, 'YPO' => 1115, 'GRO_CPGA' => 1001, 'CL' => 1006, 'MIRO' => 1077, 'OGMD' => 1085, 'RID' => 1057, 'NPO' => 1083, 'FMA' => 1053, 'MPATH' => 1031, 'IDO' => 1092, 'NCIt' => 1032, 'NIF_Dysfunction' => 1381, 'IAO' => 1393, 'SSO' => 1394, 'GAZ' => 1397, 'LDA' => 1398, 'ICNP' => 1401, 'NIF_Cell' => 1402, 'UBERON' => 1404, 'TEDDY' => 1407, 'PKO' => 1409, 'KiSAO' => 1410, 'ICF' => 1411, 'SWO' => 1413, 'OGMS' => 1414, 'CTCAE' => 1415, 'FLU' => 1417, 'TOK' => 1418, 'TAXRANK' => 1419, 'MDR' => 1422, 'RXNORM' => 1423, 'NDDF' => 1424, 'ICD10PCS' => 1425, 'MDDB' => 1426, 'RCD' => 1427, 'NIC' => 1428, 'ICPC2P' => 1429, 'AIR' => 1430, 'MCBCC' => 1438, 'GFO' => 1439, 'GFO-Bio' => 1440, 'CHEMINF' => 1444, 'HL7' => 1343, 'TMO' => 1461, 'ICECI' => 1484, 'bodysystem' => 1487, 'JERM' => 1488, 'OAE' => 1489, 'PD_ST' => 1490, 'IMGT' => 1491, 'TMA' => 1494, 'pma' => 1497, 'EDAM' => 1498, 'RNAO' => 1500, 'NeoMarkOntology' => 1501, 'CPT' => 1504, 'OMIT' => 1505, 'GO-EXT' => 1506, 'CCO' => 1507, 'ICPS' => 1509, 'MTHCH' => 1510, 'INO' => 1515, 'ICD10' => 1516, 'EHDAA2' => 1517, 'LSM' => 1520, 'NeuMORE' => 1521, 'BP' => 1522, 'oboe-sbc' => 1523, 'OBOE' => 1524, 'CSP' => 1526, 'VANDF' => 1527, 'HUGO' => 1528, 'HCPCS' => 1529, 'ADW' => 1530, 'SIO' => 1532, 'BAO' => 1533, 'apollo' => 1534, 'TAHH' => 1535, 'TAHE' => 1536, 'IDOBRU' => 1537, 'RoleO' => 1538, 'NIGO' => 1539, 'DDI' => 1540, 'MCCL' => 1541, 'CO' => 1544, 'CO_Wheat' => 1545, 'PHARE' => 1550, 'REPO' => 1552, 'ICD10CM' => 1553, 'VSAO' => 1555, 'CogPO' => 1560, 'OMRSE' => 1565, 'PVOnto' => 1567, 'AEO' => 1568, 'HPIO' => 1569, 'TM-CONST' => 1570, 'TM-OTHER-FACTORS' => 1571, 'TM-SIGNS-AND-SYMPTS' => 1572, 'TM-MER' => 1573, 'vHOG' => 1574, 'ExO' => 1575, 'FDA-MedDevice' => 1576, 'HOM_EHS' => 1578, 'AERO' => 1580, 'HLTH_INDICS' => 1581, 'CAO' => 1582, 'CMO' => 1583, 'MMO' => 1584, 'XCO' => 1585, 'OntoOrpha' => 1586, 'PO' => 1587, 'OntoDT' => 1588, 'HOM_MDCs_DRGs' => 1596, 'BDO' => 1613, 'IxnO' => 1614, 'Chem2Bio2OWL' => 1615, 'PhylOnt' => 1616, 'NBO' => 1621, 'HOM-I9PCS' => 1625, 'EMO' => 1626, 'HOMERUN' => 1627, 'HOM-UCARE' => 1629, 'HOM-EPIC' => 1630, 'HOM-HARVARD' => 1631, 'WSIO' => 1632, 'cogat' => 1633, 'OntoDM-core' => 1638, 'EpilepOnto' => 1639, 'PedTerm' => 1640, 'HOM-I9-ECODES' => 1641, 'HOM-DXPCS_MDCDRG' => 1642, 'HOM-PCS_OSHPD' => 1643, 'HOM-VCODES_OSHPD' => 1647, 'HOM-SRCE_OSHPD' => 1648, 'HOM-OSHPD' => 1649, 'UnitsOntology' => 1650, 'SDO' => 1651, 'HOM-OSHPD_UseCas' => 1652, 'HOM-PROCS2' => 1653, 'HOM-DXVCODES2' => 1654, 'pharmgkb-owl' => 1655, 'phenomeblast-owl' => 1656, 'CAMRQ' => 1657, 'invertebrata' => 1658, 'VT' => 1659, 'EPIC-SRC' => 1660, 'HOM-TX' => 1661, 'SHR' => 1665, 'MFOEM' => 1666, 'SRC-OSHPDSC' => 1667, 'HOM-OSHPD-SC' => 1668, 'ICDO3' => 1670, 'QIBO' => 1671, 'dikb-evidence' => 1672, 'RCTOntology' => 1676, 'TestHDB' => 1682, 'NeoMark' => 1686, 'FYPO' => 1689, 'yipd' => 1691, 'ICD9toICD10PCS' => 1693, 'HOM-CPT' => 1694, 'SYN' => 1696, 'HOM-ORTHO' => 1697, 'DATASRC-ORTHO' => 1698, 'vivo' => 1699, 'HOM-ORTHOSURG' => 1701, 'eufut' => 1702, 'MCV' => 3000, 'HOM-I9I10MAPS' => 3001, 'MF' => 3002, 'CNO' => 3003, 'NatPrO' => 3004, 'OoEVV' => 3006, 'HOM-ICU' => 3007, 'CareLex' => 3008, 'MEO' => 3009, 'NonRCTOntology' => 3012, 'DiagnosticOnt' => 3013, 'PMR' => 3015, 'ERO' => 3016, 'GCC' => 3017, 'HOM-PCSTEST' => 3018, 'RH-MESH' => 3019, 'CPO' => 3020, 'ATC' => 3021, 'BioModels' => 3022, 'PTSD' => 3024, 'CTX' => 3025, 'SOY' => 3028, 'SPTO' => 3029, 'CanCO' => 3030, 'QUDT' => 3031, 'HOM-UPENNMEDS' => 3032, 'thesaurus' => 3034, 'ontologia' => 3035, 'thealternativa' => 3037, 'HOM-TEST' => 3038, 'TEO' => 3042, 'HOM-MEDABBS' => 3043, 'HOM-TESTKM' => 3044, 'HOM-I9CM' => 3045, 'MDCDRG' => 3046, 'HOM-DEMOGR' => 3047, 'uni-ece' => 3048, 'PFO' => 3049, 'PhenXTK' => 3050, 'DwC' => 3058, 'BO' => 3059, 'HOM-DATSRCTESTo' => 3061, 'i2b2-patvisdims' => 3062, 'HOM-DATASRCTESTn' => 3064, 'HOM-EPICI2B2' => 3065, 'OntoDM-KDD' => 3077, 'PhenX' => 3078, 'HOMICD910PCS-150' => 3080, 'dsfs' => 3081, 'HOM-I910TESTPLUS' => 3084, 'HOM-ORTHOTEST' => 3087, 'HOM-OCHILDTEST' => 3089, 'OntoMA' => 3090, 'HOM-CLINIC' => 3092, 'DwC_test' => 3094, 'HOM-OCC' => 3104, 'CCONT' => 3108, 'RPO' => 3114, 'OBIws' => 3119, 'pco' => 3120, 'VSO' => 3124, 'profectus.oshpd.installation.5931' => 3125, 'NIF-Subcell' => 3126, 'ImmDis' => 3127, 'ConsentOntology' => 3129, 'prov-o' => 3131, 'nhds.13896' => 3134, 'cms.36739' => 3135, 'HOM-NHDS' => 3136, 'ONSTR' => 3137, 'miRNAO' => 3139, 'I9I10CMMOST' => 3143, 'HOM-CMS' => 3146, 'Clinical_Eval' => 3147, 'BRIDG' => 3150, 'GeXO' => 3151, 'ReXO' => 3152, 'NTDO' => 3153, 'oshpd.33038' => 3154, 'OntoKBCF' => 3155, 'chi.63559' => 3156, 'GeneTrial' => 3157, 'SWEET' => 3158, 'VariO' => 3159, 'ReTO' => 3162, 'HOM-CHI' => 3163, 'HOM-CHICMS' => 3164, 'HOM-GLOB' => 3167, 'GlycO' => 3169, 'shrine.20676' => 3172, 'IDODEN' => 3174, 'MetaCT' => 3175, 'XeO' => 3176, 'gs1' => 3177, 'ThomCan' => 3178, 'Genomic-CDS' => 3179, 'MEDO' => 3180, 'OntoPneumo' => 3181, 'bd-test2' => 3182, 'IFAR' => 3183, 'ZIP3' => 3184, 'GPI' => 3185, 'LOINC' => 3186, 'avnguyen-test1' => 3187, 'avnguyen-test2' => 3188, 'Top-Menelas' => 3189, 'PathLex' => 3190, 'MPO' => 3191, 'MCCV' => 3192, 'journal-test' => 3193, 'Phenoscape-ext' => 3194, 'ICD09' => 3195, 'testvdb' => 3196, 'HIMC-CPT' => 3197, 'SemPhysKB-Human' => 3198, 'UCSF-ICD910CM' => 3199, 'ZIP' => 3200, 'biocode' => 3201, 'Pizza-Example' => 3202, 'HINO' => 3203, 'PORO' => 3204, 'ICD0' => 3205, 'HCPCS-HIMC' => 3206, 'ATOL' => 3207, 'IDQA' => 3208, 'OPE' => 3209, 'TRAK' => 3210, 'NCBO_TEST_NOTES' => 3211, 'glycoprot' => 3212, 'UCSD' => 3213, 'OGSF' => 3214, 'mixs' => 3215, 'BAO_GPCR' => 3216, 'CABRO' => 3217, 'TrOn' => 3218, 'MTHMST' => 3219, 'MTHMSTFRE' => 3220}

      def get_ontology_virtual_id(acronym)
        ONTOLOGY_ACRONYM_MAP[acronym]
      end

      def get_options(params={})
        options = {}
        # The ENV["REMOTE_USER"] object (this is a variable that stores a per-request instance of
        # a LinkedData::Models::User object based on the API Key used in the request). The apikey
        # is one of the attributes on the user object.
        user = ENV["REMOTE_USER"]
        if user.nil?
          # Fallback to APIKEY from config/env/dev
          options[:apikey] = LinkedData.settings.apikey
        else
          options[:apikey] = user.apikey
        end
        #
        # Generic parameters that can apply to any endpoint.
        #
        #* elements={element1,element2}
        element = [params["elements"]].compact
        options[:elementid] = element unless element.nil? || element.empty?
        #
        #* resources={resource1,resource2}
        resource = [params["resources"]].compact
        options[:resourceids] = resource unless resource.nil? || resource.empty?
        #
        #* ontologies={acronym1,acronym2,acronym3}
        ontologies = [params["ontologies"]].compact
        ontologies.map! {|acronym| get_ontology_virtual_id(acronym) }
        options[:ontologiesToExpand]       = ontologies
        options[:ontologiesToKeepInResult] = ontologies
        #
        #* semantic_types={semType1,semType2,semType3}
        semanticTypes = [params["semantic_types"]].compact
        options[:semanticTypes] = semanticTypes unless semanticTypes.nil? || semanticTypes.empty?
        #
        #* max_level={0..N}
        options[:levelMax] = params["max_level"] if params.key?("max_level")
        #
        #* mapping_types={automatic,manual}
        mapping_types = [params["mapping_types"]].compact
        options[:mappingTypes] = mapping_types unless mapping_types.empty?
        #
        #* exclude_numbers={true|false}
        options[:filterNumber] = params["exclude_numbers"] if params.key?("exclude_numbers")
        #
        #* minimum_match_length={0..N}
        options[:minTermSize] = params["minimum_match_length"] if params.key?("minimum_match_length")
        #
        #* include_synonyms={true|false}
        options[:withSynonyms] = params["include_synonyms"] if params.key?("include_synonyms")
        #
        #* include_offsets={true|false}
        # TODO: code this one!

        #
        #* mode={union|intersection}
        options[:mode] = params["mode"] if params.key?("mode")
        #
        # Stop words
        #
        #* exclude_words={word1,word2,word3}
        #* excluded_words_are_case_sensitive={true|false}
        exclude_words = [params["exclude_words"]].compact
        options[:stopWords] = exclude_words
        options[:withDefaultStopWords] = false if not exclude_words.empty?
        case_sensitive = params["excluded_words_are_case_sensitive"]
        options[:isStopWordsCaseSensitive] = case_sensitive unless case_sensitive.nil?

        return options
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
