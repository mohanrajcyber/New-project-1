package app.pockethost.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EngineContractTest {
    @Test
    fun unavailableIsNotRunning() {
        val result = EngineResult.Unavailable("no qemu", "use Termux")
        assertTrue(result.reason.contains("qemu"))
        assertEquals("use Termux", result.nextStep)
    }

    @Test
    fun startedNoteIsExplicit() {
        val result = EngineResult.Started("serial console attached")
        assertFalse(result.note.isBlank())
    }
}
