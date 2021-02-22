# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bulwark::PennQualifiedCore::TransformMarc do
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
      "display_call_number" => ["Folio TN664 .E7 1598"]
    }
  end
  let(:xml) { fixture_to_str('marmite', 'marc_xml', '9923478503503681.xml') }

  it 'generates_expected_xml' do
    expect(
      described_class.from_marc_xml(xml)
    ).to eq expected_pqc
  end

  it 'raises error when xml is invalid' do
    expect {
      described_class.from_marc_xml('')
    }.to raise_error StandardError, 'Error mapping MARC XML to PQC: NoMethodError undefined method `text\' for nil:NilClass'
  end
end
