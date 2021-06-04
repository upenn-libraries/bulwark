# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulwark::PennQualifiedCore::TransformMarc do
  describe '.from_marc_xml' do
    context 'for a general use case' do
      let(:expected_pqc) do
        {
          "identifier" => ["sts- n.r* n.n. di12 (3) 1598 (A)", "(OCoLC)ocm16660686", "(OCoLC)16660686", "2347850", "(PU)2347850-penndb-Voyager"],
          "creator" => ["Ercker, Lazarus,"],
          "title" => [
            "Beschreibung aller fürnemisten Mineralischen Ertzt vnnd Berckwercksarten :",
            "wie dieselbigen vnd eine jede in Sonderheit jrer Natur vnd Eygenschafft nach, auff alle Metalla probirt, vnd im kleinen Fewr sollen versucht werden, mit Erklärung etlicher fürnemer nützlicher Schmeltzwerck im grossen Feuwer, auch Scheidung Goldts, Silbers, vnd anderer Metalln, sampt einem Bericht des Kupffer Saigerns, Messing brennens, vnd Salpeter Siedens, auch aller saltzigen Minerischen proben, vnd was denen allen anhengig : in fünff Bücher verfast, dessgleichen zuvorn niemals in Druck kommen ... : auffs newe an vielen Orten mit besserer Aussführung, vnd mehreren Figurn erklärt /",
            "durch den weitberühmten Lazarum Erckern, der Röm. Kay. May. Obersten Bergkmeister vnd Buchhalter in Königreich Böhem  ..."
          ],
          "publisher" => ["Gedruckt zu Franckfurt am Mayn : Durch Johan Feyerabendt, 1598."],
          "relation" => ["https://colenda.library.upenn.edu/catalog/81431-p3df6k90j"],
          "format" => ["[4], 134, [4] leaves : ill. ; 31 cm. (fol.)"],
          "bibliographic_note" => ["Leaves printed on both sides. Signatures: )(⁴ A-Z⁴ a-k⁴ l⁶. The last leaf is blank. Woodcut illustrations, initials and tail-pieces. Title page printed in black and red. Printed marginalia. \"Erratum\" on verso of last printed leaf. Online version available via Colenda https://colenda.library.upenn.edu/catalog/81431-p3df6k90j"],
          "provenance" => ["Smith, Edgar Fahs, 1854-1928 (autograph, 1917)", "Wright, H. (autograph, 1870)"],
          "description" => ["Penn Libraries copy has Edgar Fahs Smith's autograph on front free endpaper; autograph of H. Wright on front free endpaper; effaced ms. inscription (autograph?) on title leaf."],
          "subject" => ["Metallurgy -- Early works to 1800.", "Assaying -- Early works to 1800.", "PU", "PU", "PU"],
          "date" => ["1598"],
          "personal_name" => ["Feyerabend, Johann,"],
          "geographic_subject" => ["Germany -- Frankfurt am Main."],
          "collection" => ["Edgar Fahs Smith Memorial Collection (University of Pennsylvania)"],
          "call_number" => ["Folio TN664 .E7 1598"]
        }
      end
      let(:xml) { fixture_to_str('marmite', 'marc_xml', '9923478503503681.xml') }

      it 'generates_expected_xml' do
        expect(described_class.from_marc_xml(xml)).to eq expected_pqc
      end
    end

    context 'for a manuscript' do
      let(:expected_pqc) do
        {
          "abstract" => ["Beginning of Sigebert of Gembloux's continuation of the chronicle of Jerome, in which he traces the reigns of kings of various kingdoms.  The last reference is to Pope Zosimus (417 CE; f. 6v)."],
          "bibliographic_note" => ["Ms. gathering. Title supplied by cataloger. Collation:  Paper, 10; 1² 2⁸ (f. 7-10 blank). Layout:  Written in 47-50 long lines; frame-ruled in lead. Script:  Written in Gothic cursive script. Decoration: 4-line initial (f. 2r) and 3-line initial (f. 1r) in red; paragraph marks in red followed by initials slashed with red on first page (f. 1r). Binding:  Bound with Strabo's Geographia (Paris:  Gourmont, 1512) in 18th-century calf including gilt spine title Initium Chronic[i] Sicebert[i] MS. Origin:  Probably written in Belgium, possibly in Gembloux (inscription on title page of printed work, Bibliotheca Gemblacensis), in the late 15th century (Zacour-Hirsch)."],
          "call_number" => ["Folio GrC St812 Ef512g"],
          "citation_note" => ["Described in Zacour, Norman P. and Hirsch, Rudolf. Catalogue of Manuscripts in the Libraries of the University of Pennsylvania to 1800 (Philadelphia: University of Pennsylvania Press, 1965), Supplement A (1) Library Chronicle 35 (1969),"],
          "creator" => ["Sigebert,"],
          "format" => ["10 leaves : paper ; 263 x 190 mm. bound to 218 x 155 mm."],
          "identifier" => ["(OCoLC)ocn873818335", "(OCoLC)873818335", "(PU)6126353-penndb-Voyager"],
          "item_type" => ["Manuscripts"],
          "language" => ["Latin."],
          "personal_name" => ["Sigebert,"],
          "provenance" => ["Sold by Bernard M. Rosenthal (New York), 1964."],
          "publisher" => ["[Belgium], [between 1475 and 1499?]"],
          "relation" => ["http://hdl.library.upenn.edu/1017/d/medren/9961263533503681"],
          "subject" => ["World history -- Early works to 1800.", "Chronicles.", "Manuscripts, Latin", "15th century.", "Manuscripts, Renaissance."],
          "title" => ["[Partial copy of Chronicon]", "[manuscript].", "Initium Chronici Siceberti."]
        }
      end
      let(:xml) { fixture_to_str('marmite', 'marc_xml', 'manuscript.xml') }

      it 'generates expected xml' do
        expect(described_class.from_marc_xml(xml)).to eq expected_pqc
      end
    end

    context 'when xml is invalid' do
      it 'raises an error' do
        expect {
          described_class.from_marc_xml('')
        }.to raise_error StandardError, 'Error mapping MARC XML to PQC: NoMethodError undefined method `text\' for nil:NilClass'
      end
    end
  end

  describe '.manuscript?' do
    let(:nokogiri_xml) do
      document = Nokogiri::XML(xml)
      document.remove_namespaces!
      document
    end
    context 'when PAULM is present in 040 field' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1=" " ind2=" " tag="040">
                <marc:subfield code="a">PAULM</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'returns true' do
        expect(described_class.manuscript?(nokogiri_xml)).to be true
      end
    end

    context 'when appm2 is present in field 040 subfield e' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record>
              <marc:datafield ind1=" " ind2=" " tag="040">
                <marc:subfield code="e">appm2</marc:subfield>
              </marc:datafield>
            </marc:record>
          </marc:records>
        XML
      end

      it 'returns true' do
        expect(described_class.manuscript?(nokogiri_xml)).to be true
      end
    end

    context 'when field 040 is empty' do
      let(:xml) do
        <<~XML
          <?xml version="1.0"?>
          <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:record/>
          </marc:records>
        XML
      end

      it 'returns false' do
        expect(described_class.manuscript?(nokogiri_xml)).to be false
      end
    end
  end
end
