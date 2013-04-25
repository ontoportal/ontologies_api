require_relative '../test_case'

class TestAnnotatorController < TestCase

  def setup
  end

  def teardown
  end

  def test_annotate
    text = <<eos
Ginsenosides chemistry, biosynthesis, analysis, and potential health effects in software concept or data." "Ginsenosides are a special group of triterpenoid saponins that can be classified into two groups by the skeleton of their aglycones, namely dammarane- and oleanane-type. Ginsenosides are found nearly exclusively in Panax species (ginseng) and up to now more than 150 naturally occurring ginsenosides have been isolated from roots, leaves/stems, fruits, and/or flower heads of ginseng. The same concept indicates Ginsenosides have been the target of a lot of research as they are believed to be the main active principles behind the claims of ginsengs efficacy. The potential health effects of ginsenosides that are discussed in this chapter include anticarcinogenic, immunomodulatory, anti-inflammatory, antiallergic, antiatherosclerotic, antihypertensive, and antidiabetic effects as well as antistress activity and effects on the central nervous system. Ginsensoides can be metabolized in the stomach (acid hydrolysis) and in the gastrointestinal tract (bacterial hydrolysis) or transformed to other ginsenosides by drying and steaming of ginseng to more bioavailable and bioactive ginsenosides. The metabolization and transformation of intact ginsenosides, which seems to play an important role for their potential health effects, are discussed. Qualitative and quantitative analytical techniques for the analysis of ginsenosides are important in relation to quality control of ginseng products and plant material and for the determination of the effects of processing of plant material as well as for the determination of the metabolism and bioavailability of ginsenosides. Analytical techniques for the analysis of ginsenosides that are described in this chapter are thin-layer chromatography (TLC), high-performance liquid chromatography (HPLC) combined with various detectors, gas chromatography (GC), colorimetry, enzyme immunoassays (EIA), capillary electrophoresis (CE), nuclear magnetic resonance (NMR) spectroscopy, and spectrophotometric methods.
eos
    params = {text: text}
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)
  end

  def test_annotate_hierarchy
    text = "Aggregate Human Data chromosomal mutation Aggregate Human Data chromosomal deletion Aggregate Human Data Resource Federal Funding Resource receptor antagonists chromosomal mutation"

    params = {text: text, max_level: 5}
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)
    #paul: here you can reproduce the serializer output

    #TODO
    #this test is a replication of what is tested in linked data
    #just to be sure that the serializer works correctly

  end
end
