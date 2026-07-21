package app.tiktoklivecompanion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class StreamNameNormalizerTest {
    @Test fun `akzeptiert Namen mit fuehrendem At`() = assertEquals("creator", StreamNameNormalizer.normalize("@creator"))
    @Test fun `akzeptiert Namen ohne At`() = assertEquals("creator", StreamNameNormalizer.normalize("creator"))
    @Test fun `trimmt Leerzeichen und senkt Grossbuchstaben`() = assertEquals("crea.tor_1", StreamNameNormalizer.normalize("  @Crea.Tor_1  "))
    @Test fun `lehnt leere Eingabe ab`() = assertNull(StreamNameNormalizer.normalize("   "))
    @Test fun `lehnt nur At ab`() = assertNull(StreamNameNormalizer.normalize("@"))
    @Test fun `lehnt Sonderzeichen ab`() = assertNull(StreamNameNormalizer.normalize("crea<script>"))
    @Test fun `lehnt Pfad-Injektion ab`() = assertNull(StreamNameNormalizer.normalize("creator/../evil"))
    @Test fun `lehnt Leerzeichen im Namen ab`() = assertNull(StreamNameNormalizer.normalize("crea tor"))
    @Test fun `lehnt ueberlange Namen ab`() = assertNull(StreamNameNormalizer.normalize("a".repeat(25)))
    @Test fun `baut korrekte Live-URL`() = assertEquals("https://www.tiktok.com/@creator/live", StreamNameNormalizer.liveUrl("@Creator"))
    @Test fun `liveUrl null bei ungueltig`() = assertNull(StreamNameNormalizer.liveUrl("!!"))
}
